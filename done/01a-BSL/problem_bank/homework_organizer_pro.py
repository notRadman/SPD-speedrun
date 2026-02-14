import os
import shutil
from pathlib import Path
from datetime import datetime

def organize_homework_files(target_directory="."):
    """
    ينظم ملفات الواجبات بحيث يضع كل مهمة في فولدر منفصل
    ويحط الحل في ملف solution منفصل
    ويخلق ملف log.md يوضح العمليات المنجزة
    """
    
    target_path = Path(target_directory)
    
    if not target_path.exists():
        print(f"❌ المجلد {target_directory} غير موجود!")
        return
    
    print(f"🔄 بدء تنظيم ملفات الواجبات في المجلد: {target_path.absolute()}")
    
    # البحث عن الملفات في المجلد الحالي فقط (بدون المجلدات الفرعية)
    rkt_files = [f for f in target_path.iterdir() 
                 if f.is_file() and f.suffix == '.rkt']
    
    print(f"📁 تم العثور على {len(rkt_files)} ملف .rkt")
    
    # تجميع الملفات حسب أسماء المهام
    homework_groups = {}
    
    for file in rkt_files:
        filename = file.stem  # اسم الملف بدون الامتداد
        
        # التحقق من وجود starter أو solution في اسم الملف
        if '-starter' in filename:
            task_name = filename.replace('-starter', '')
            if task_name not in homework_groups:
                homework_groups[task_name] = {}
            homework_groups[task_name]['starter'] = file
            
        elif '-solution' in filename:
            task_name = filename.replace('-solution', '')
            if task_name not in homework_groups:
                homework_groups[task_name] = {}
            homework_groups[task_name]['solution'] = file
    
    print(f"🎯 تم اكتشاف {len(homework_groups)} مهمة")
    
    # إنشاء المجلدات ونقل الملفات
    log_entries = []
    log_entries.append("# 📋 تقرير تنظيم ملفات الواجبات")
    log_entries.append("")
    log_entries.append(f"**📅 التاريخ والوقت:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log_entries.append(f"**📂 المجلد المستهدف:** `{target_path.absolute()}`")
    log_entries.append(f"**👤 نظام التشغيل:** {os.name}")
    log_entries.append("")
    log_entries.append("---")
    log_entries.append("")
    
    successful_operations = 0
    warnings = 0
    
    for task_name, files in homework_groups.items():
        print(f"\n🔄 معالجة المهمة: {task_name}")
        
        # التأكد من وجود كلا الملفين (starter و solution)
        if 'starter' in files and 'solution' in files:
            # إنشاء مجلد المهمة
            task_folder = target_path / task_name
            
            try:
                task_folder.mkdir(exist_ok=True)
                print(f"  📁 تم إنشاء المجلد: {task_name}/")
                
                log_entries.append(f"## 🎯 المهمة: {task_name}")
                log_entries.append(f"**📂 المجلد المنشأ:** `{task_name}/`")
                log_entries.append("")
                
                # نقل ملف starter
                starter_dest = task_folder / files['starter'].name
                shutil.move(str(files['starter']), str(starter_dest))
                print(f"  ✅ تم نقل: {files['starter'].name}")
                log_entries.append(f"- ✅ **ملف البداية:** `{files['starter'].name}`")
                
                # إنشاء فولدر الحل داخل مجلد المهمة
                solution_folder = task_folder / "solution"
                solution_folder.mkdir(exist_ok=True)
                print(f"  📁 تم إنشاء فولدر الحل: solution/")
                
                # نقل ملف solution إلى فولدر الحل
                solution_dest = solution_folder / files['solution'].name
                shutil.move(str(files['solution']), str(solution_dest))
                print(f"  📝 تم نقل الحل إلى: solution/{files['solution'].name}")
                
                log_entries.append(f"- 📁 **فولدر الحل:** `solution/`")
                log_entries.append(f"- 📝 **ملف الحل:** `solution/{files['solution'].name}`")
                log_entries.append("")
                
                successful_operations += 1
                print(f"  ✨ تم تنظيم المهمة بنجاح!")
                
            except Exception as e:
                print(f"  ❌ خطأ في معالجة المهمة: {str(e)}")
                log_entries.append(f"- ❌ **خطأ:** {str(e)}")
                log_entries.append("")
        else:
            # في حالة وجود ملف واحد فقط
            warnings += 1
            missing_type = "solution" if 'starter' in files else "starter"
            existing_file = files.get('starter') or files.get('solution')
            
            print(f"  ⚠️ ملف {missing_type} مفقود!")
            print(f"     الملف الموجود: {existing_file.name}")
            
            log_entries.append(f"## ⚠️ تحذير: {task_name}")
            log_entries.append(f"**❗ حالة:** ملف `{missing_type}` مفقود")
            log_entries.append(f"- 📄 **الملف الموجود:** `{existing_file.name}`")
            log_entries.append(f"- 🔍 **المطلوب:** البحث عن ملف `{task_name}-{missing_type}.rkt`")
            log_entries.append("")
    
    # إضافة الإحصائيات النهائية
    log_entries.append("---")
    log_entries.append("")
    log_entries.append("## 📊 الإحصائيات النهائية")
    log_entries.append("")
    log_entries.append(f"| المؤشر | القيمة |")
    log_entries.append(f"|--------|--------|")
    log_entries.append(f"| 🎯 إجمالي المهام المكتشفة | {len(homework_groups)} |")
    log_entries.append(f"| ✅ العمليات الناجحة | {successful_operations} |")
    log_entries.append(f"| ⚠️ التحذيرات | {warnings} |")
    
    if len(homework_groups) > 0:
        success_rate = (successful_operations * 100) // len(homework_groups)
        log_entries.append(f"| 📈 معدل النجاح | {success_rate}% |")
    
    log_entries.append("")
    log_entries.append("---")
    log_entries.append("")
    log_entries.append("### 📝 ملاحظات:")
    log_entries.append("- تم نقل ملفات البداية (starter) إلى المجلد الرئيسي للمهمة")
    log_entries.append("- تم نقل ملفات الحلول (solution) إلى فولدر منفصل بداخل كل مهمة")
    log_entries.append("- كل مهمة لها فولدر خاص بها يحتوي على ملف البداية وفولدر الحل")
    log_entries.append("")
    log_entries.append("*تم إنتاج هذا التقرير تلقائياً بواسطة منظم ملفات الواجبات* 🤖")
    
    # كتابة ملف السجل
    log_content = "\n".join(log_entries)
    log_file = target_path / "log.md"
    
    try:
        with open(log_file, 'w', encoding='utf-8') as f:
            f.write(log_content)
        print(f"\n📋 تم حفظ تقرير مفصل في: {log_file}")
    except Exception as e:
        print(f"\n❌ خطأ في كتابة ملف السجل: {str(e)}")
    
    # طباعة النتائج النهائية
    print(f"\n🎉 تم الانتهاء من التنظيم!")
    print(f"📊 الإحصائيات:")
    print(f"   • المهام المكتشفة: {len(homework_groups)}")
    print(f"   • العمليات الناجحة: {successful_operations}")
    print(f"   • التحذيرات: {warnings}")
    
    if successful_operations > 0:
        print(f"✨ تم تنظيم {successful_operations} مهمة بنجاح!")
        print("📁 كل مهمة لها فولدر، وكل حل في فولدر منفصل بداخلها")
    else:
        print("⚠️ لم يتم العثور على مهام كاملة للتنظيم")
    
    return successful_operations, len(homework_groups)

if __name__ == "__main__":
    # تشغيل السكريبت في المجلد الحالي
    organize_homework_files()
    
    # أو يمكنك تحديد مجلد معين
    # organize_homework_files("/path/to/your/homework/folder")
