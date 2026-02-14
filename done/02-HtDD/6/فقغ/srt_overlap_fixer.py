import re
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Tuple, Optional

class SubtitleEntry:
    """Class لتمثيل subtitle واحد"""
    def __init__(self, index: int, start: datetime, end: datetime, text: str):
        self.index = index
        self.start = start
        self.end = end
        self.text = text
        self.modified = False
        self.original_end = end
    
    def __repr__(self):
        return f"Sub#{self.index}: {self.format_time(self.start)} --> {self.format_time(self.end)}"
    
    @staticmethod
    def format_time(dt: datetime) -> str:
        """تحويل datetime لصيغة SRT (00:00:00,000)"""
        return dt.strftime("%H:%M:%S,%f")[:-3]
    
    def to_srt_block(self) -> str:
        """تحويل الـ entry لـ SRT format"""
        return f"{self.index}\n{self.format_time(self.start)} --> {self.format_time(self.end)}\n{self.text}\n"


class SRTProcessor:
    """معالج ملفات SRT"""
    
    TIME_PATTERN = re.compile(r'(\d{2}):(\d{2}):(\d{2}),(\d{3})')
    GAP_MS = 100  # الفجوة بين الـ subtitles بالميلي ثانية
    
    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.subtitles: List[SubtitleEntry] = []
        self.overlaps_found = 0
        self.overlaps_fixed = 0
        self.log_entries: List[str] = []
        
    def parse_time(self, time_str: str) -> datetime:
        """تحويل string الوقت لـ datetime object"""
        match = self.TIME_PATTERN.match(time_str)
        if not match:
            raise ValueError(f"صيغة الوقت غير صحيحة: {time_str}")
        
        h, m, s, ms = map(int, match.groups())
        return datetime(2000, 1, 1, h, m, s, ms * 1000)
    
    def read_srt(self) -> bool:
        """قراءة ملف SRT"""
        try:
            with open(self.filepath, 'r', encoding='utf-8-sig') as f:
                content = f.read()
            
            # تقسيم الملف لـ blocks
            blocks = re.split(r'\n\s*\n', content.strip())
            
            for block in blocks:
                lines = block.strip().split('\n')
                if len(lines) < 3:
                    continue
                
                try:
                    index = int(lines[0])
                    time_line = lines[1]
                    text = '\n'.join(lines[2:])
                    
                    # استخراج أوقات البداية والنهاية
                    times = time_line.split(' --> ')
                    if len(times) != 2:
                        continue
                    
                    start = self.parse_time(times[0].strip())
                    end = self.parse_time(times[1].strip())
                    
                    self.subtitles.append(SubtitleEntry(index, start, end, text))
                except (ValueError, IndexError) as e:
                    self.log_entries.append(f"⚠️ تخطي subtitle #{lines[0]}: {str(e)}")
                    continue
            
            self.log_entries.append(f"✅ تم قراءة {len(self.subtitles)} subtitle بنجاح")
            return True
            
        except Exception as e:
            self.log_entries.append(f"❌ خطأ في قراءة الملف: {str(e)}")
            return False
    
    def detect_and_fix_overlaps(self) -> int:
        """اكتشاف وإصلاح التعارضات الزمنية"""
        if len(self.subtitles) < 2:
            return 0
        
        gap = timedelta(milliseconds=self.GAP_MS)
        
        for i in range(len(self.subtitles) - 1):
            current = self.subtitles[i]
            next_sub = self.subtitles[i + 1]
            
            # فحص التعارض
            if current.end > next_sub.start:
                self.overlaps_found += 1
                
                # حساب مقدار التعارض
                overlap = (current.end - next_sub.start).total_seconds() * 1000
                
                # تصحيح: نخلي نهاية الـ current قبل بداية الـ next بفجوة صغيرة
                new_end = next_sub.start - gap
                
                # التأكد إن النهاية الجديدة مش قبل البداية
                if new_end > current.start:
                    current.end = new_end
                    current.modified = True
                    self.overlaps_fixed += 1
                    
                    self.log_entries.append(
                        f"🔧 تم إصلاح تعارض في Subtitle #{current.index}:\n"
                        f"   - التعارض: {overlap:.0f}ms\n"
                        f"   - الوقت الأصلي: {SubtitleEntry.format_time(current.original_end)}\n"
                        f"   - الوقت الجديد: {SubtitleEntry.format_time(current.end)}"
                    )
                else:
                    self.log_entries.append(
                        f"⚠️ لا يمكن إصلاح Subtitle #{current.index}: النهاية ستكون قبل البداية"
                    )
        
        return self.overlaps_fixed
    
    def write_srt(self, output_path: Optional[Path] = None) -> bool:
        """كتابة ملف SRT المعدل"""
        if output_path is None:
            output_path = self.filepath
        
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                for i, sub in enumerate(self.subtitles):
                    f.write(sub.to_srt_block())
                    if i < len(self.subtitles) - 1:
                        f.write('\n')
            
            self.log_entries.append(f"✅ تم حفظ الملف المعدل: {output_path}")
            return True
            
        except Exception as e:
            self.log_entries.append(f"❌ خطأ في كتابة الملف: {str(e)}")
            return False
    
    def create_backup(self) -> bool:
        """إنشاء نسخة احتياطية من الملف الأصلي"""
        try:
            backup_path = self.filepath.with_suffix('.srt.backup')
            backup_path.write_text(self.filepath.read_text(encoding='utf-8'), encoding='utf-8')
            self.log_entries.append(f"💾 تم إنشاء نسخة احتياطية: {backup_path}")
            return True
        except Exception as e:
            self.log_entries.append(f"⚠️ فشل إنشاء النسخة الاحتياطية: {str(e)}")
            return False
    
    def generate_markdown_log(self, log_path: Path) -> bool:
        """إنشاء ملف markdown بتفاصيل العملية"""
        try:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            md_content = f"""# SRT Time Overlap Fix Log

## معلومات العملية
- **الملف**: `{self.filepath.name}`
- **المسار**: `{self.filepath.absolute()}`
- **التاريخ والوقت**: {timestamp}
- **عدد الـ Subtitles**: {len(self.subtitles)}

## النتائج
- ✅ **التعارضات المكتشفة**: {self.overlaps_found}
- 🔧 **التعارضات المُصلحة**: {self.overlaps_fixed}
- {"✅ **الحالة**: تم الإصلاح بنجاح" if self.overlaps_fixed > 0 else "ℹ️ **الحالة**: لا توجد تعارضات"}

## التفاصيل

"""
            for entry in self.log_entries:
                md_content += f"{entry}\n\n"
            
            # إضافة أمثلة على التغييرات
            modified_subs = [s for s in self.subtitles if s.modified]
            if modified_subs:
                md_content += "\n## أمثلة على التعديلات\n\n"
                for sub in modified_subs[:5]:  # أول 5 تعديلات
                    md_content += f"### Subtitle #{sub.index}\n"
                    md_content += f"```\n{sub.text[:100]}{'...' if len(sub.text) > 100 else ''}\n```\n"
                    md_content += f"- **الوقت القديم**: `{SubtitleEntry.format_time(sub.original_end)}`\n"
                    md_content += f"- **الوقت الجديد**: `{SubtitleEntry.format_time(sub.end)}`\n\n"
            
            md_content += "\n---\n*تم إنشاء هذا التقرير تلقائياً بواسطة SRT Overlap Fixer*\n"
            
            with open(log_path, 'w', encoding='utf-8') as f:
                f.write(md_content)
            
            print(f"📄 تم إنشاء ملف الـ Log: {log_path}")
            return True
            
        except Exception as e:
            print(f"❌ خطأ في إنشاء ملف الـ Log: {str(e)}")
            return False


def main():
    """الدالة الرئيسية"""
    print("=" * 60)
    print("🎬 SRT Time Overlap Fixer")
    print("=" * 60)
    
    # طلب مسار الملف من المستخدم
    if len(sys.argv) > 1:
        filepath = sys.argv[1]
    else:
        filepath = input("\n📂 أدخل مسار ملف الـ SRT: ").strip().strip('"').strip("'")
    
    if not filepath:
        print("❌ لم يتم إدخال مسار للملف!")
        return
    
    # التحقق من وجود الملف
    file_path = Path(filepath)
    if not file_path.exists():
        print(f"❌ الملف غير موجود: {filepath}")
        return
    
    if file_path.suffix.lower() != '.srt':
        print(f"⚠️ تحذير: الملف ليس بصيغة .srt")
    
    print(f"\n🔍 معالجة الملف: {file_path.name}")
    print("-" * 60)
    
    # إنشاء معالج SRT
    processor = SRTProcessor(filepath)
    
    # قراءة الملف
    if not processor.read_srt():
        print("❌ فشلت عملية قراءة الملف!")
        return
    
    print(f"✅ تم قراءة {len(processor.subtitles)} subtitle")
    
    # إنشاء نسخة احتياطية
    processor.create_backup()
    
    # اكتشاف وإصلاح التعارضات
    print("\n🔍 البحث عن تعارضات زمنية...")
    fixed = processor.detect_and_fix_overlaps()
    
    if fixed > 0:
        print(f"🔧 تم إصلاح {fixed} تعارض")
        
        # حفظ الملف المعدل
        if processor.write_srt():
            print("✅ تم حفظ التعديلات بنجاح!")
    else:
        print("✨ رائع! لا توجد تعارضات في الملف")
    
    # إنشاء ملف الـ Log
    log_path = file_path.with_name(f"{file_path.stem}_log.md")
    processor.generate_markdown_log(log_path)
    
    print("\n" + "=" * 60)
    print("✅ اكتملت العملية بنجاح!")
    print("=" * 60)


if __name__ == "__main__":
    main()
