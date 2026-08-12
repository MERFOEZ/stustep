/**
 * اختبارات قواعد أمان Firestore على المحاكي المحلي.
 *
 * لماذا اختبار آلي للقواعد وليس مراجعة بالعين؟
 * لأن قاعدة أمان خاطئة لا تُظهر خطأً في التطبيق — إما تفتح بياناتك للجميع
 * بصمت، أو تُغلقها فتظهر شاشات فارغة يُظن أنها مشكلة شبكة. الحالتان لا
 * تُكتشفان بالتجربة اليدوية، وتُكتشفان هنا في ثوانٍ.
 *
 * التشغيل:
 *   cd test/rules && npm test
 * (يشغّل محاكي Firestore تلقائياً ثم ينفّذ الاختبارات ثم يوقفه)
 */

const fs = require('fs');
const path = require('path');
const assert = require('assert');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
} = require('firebase/firestore');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');

let testEnv;

// معرّفات ثابتة تستخدمها كل الاختبارات.
const STUDENT = 'student_1';
const OTHER = 'student_2';
const ADMIN = 'admin_1';

before(async function () {
  this.timeout(60000);
  testEnv = await initializeTestEnvironment({
    projectId: 'stustep-rules-test',
    firestore: {
      rules: fs.readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  // تهيئة البيانات بتجاوز القواعد — تمثّل ما يُدخله الفريق من Console.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'admins', ADMIN), { grantedAt: 'seed' });
    await setDoc(doc(db, 'colleges', 'col_it'), { name: 'الحاسوب' });
    await setDoc(doc(db, 'admission_requirements', 'col_it'), { minGpa: 75 });
    await setDoc(doc(db, 'groups', 'g1'), { name: 'هندسة', members: [] });
    await setDoc(doc(db, 'groups/g1/messages', 'm1'), {
      senderId: STUDENT,
      text: 'مرحبا',
    });
    await setDoc(doc(db, 'housings', 'h1'), {
      createdBy: STUDENT,
      moderationStatus: 'published',
      name: 'سكن',
    });
  });
});

const asStudent = () => testEnv.authenticatedContext(STUDENT).firestore();
const asOther = () => testEnv.authenticatedContext(OTHER).firestore();
const asAdmin = () => testEnv.authenticatedContext(ADMIN).firestore();
const asGuest = () => testEnv.unauthenticatedContext().firestore();

// ===========================================================================

describe('١. الزائر غير المسجَّل ممنوع تماماً', () => {
  it('لا يقرأ الكليات', async () => {
    await assertFails(getDoc(doc(asGuest(), 'colleges', 'col_it')));
  });

  it('لا يقرأ رسائل الشات', async () => {
    await assertFails(getDoc(doc(asGuest(), 'groups/g1/messages', 'm1')));
  });

  it('لا يكتب شيئاً', async () => {
    await assertFails(
      setDoc(doc(asGuest(), 'colleges', 'hack'), { name: 'مزيّف' })
    );
  });
});

describe('٢. الشجرة الأكاديمية — قراءة للجميع وكتابة للمشرف', () => {
  it('الطالب يقرأ الكليات', async () => {
    await assertSucceeds(getDoc(doc(asStudent(), 'colleges', 'col_it')));
  });

  it('الطالب لا يستطيع تعديل كلية', async () => {
    await assertFails(
      updateDoc(doc(asStudent(), 'colleges', 'col_it'), { name: 'مخرَّب' })
    );
  });

  it('المشرف يستطيع تعديل كلية', async () => {
    await assertSucceeds(
      updateDoc(doc(asAdmin(), 'colleges', 'col_it'), { name: 'تقنية' })
    );
  });

  it('الطالب لا يستطيع تعديل شروط القبول', async () => {
    await assertFails(
      updateDoc(doc(asStudent(), 'admission_requirements', 'col_it'), {
        minGpa: 0,
      })
    );
  });

  it('المشرف يستطيع تعديل شروط القبول', async () => {
    await assertSucceeds(
      updateDoc(doc(asAdmin(), 'admission_requirements', 'col_it'), {
        minGpa: 80,
      })
    );
  });
});

describe('٣. وثيقة المستخدم', () => {
  it('المستخدم يُنشئ وثيقته', async () => {
    await assertSucceeds(
      setDoc(doc(asStudent(), 'users', STUDENT), {
        uid: STUDENT,
        name: 'أحمد',
        email: 'a@b.c',
        createdAt: 'now',
      })
    );
  });

  it('المستخدم لا يُنشئ وثيقة باسم غيره', async () => {
    await assertFails(
      setDoc(doc(asStudent(), 'users', OTHER), {
        uid: OTHER,
        name: 'منتحل',
        email: 'x@y.z',
        createdAt: 'now',
      })
    );
  });

  it('حقل غير معروف يُرفض — منع حقن صلاحيات', async () => {
    // لولا حصر الحقول لاستطاع أي مستخدم إضافة role: admin لنفسه.
    await assertFails(
      setDoc(doc(asStudent(), 'users', STUDENT), {
        uid: STUDENT,
        name: 'أحمد',
        email: 'a@b.c',
        createdAt: 'now',
        role: 'admin',
      })
    );
  });

  it('لا حذف لوثيقة المستخدم من العميل', async () => {
    await assertFails(deleteDoc(doc(asStudent(), 'users', STUDENT)));
  });
});

describe('٤. نتائج مساعد اختيار التخصص', () => {
  it('المستخدم يحفظ نتيجته', async () => {
    await assertSucceeds(
      setDoc(doc(asStudent(), `users/${STUDENT}/matcher_results`, 'r1'), {
        eligibleCount: 3,
      })
    );
  });

  it('مستخدم آخر لا يقرأ نتائج غيره', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), `users/${STUDENT}/matcher_results`, 'r1'),
        { eligibleCount: 3 }
      );
    });
    await assertFails(
      getDoc(doc(asOther(), `users/${STUDENT}/matcher_results`, 'r1'))
    );
  });
});

describe('٥. الشات — منع انتحال الهوية وحذف رسائل الغير', () => {
  it('المستخدم يرسل رسالة باسمه', async () => {
    await assertSucceeds(
      setDoc(doc(asStudent(), 'groups/g1/messages', 'new1'), {
        senderId: STUDENT,
        text: 'رسالتي',
      })
    );
  });

  it('المستخدم لا يرسل رسالة باسم غيره', async () => {
    await assertFails(
      setDoc(doc(asStudent(), 'groups/g1/messages', 'new2'), {
        senderId: OTHER,
        text: 'انتحال',
      })
    );
  });

  it('🔒 مستخدم آخر لا يحذف رسالة ليست له', async () => {
    // الثغرة الأصلية: دالة الحذف في التطبيق لا تتحقق من الملكية، والتحقق
    // الوحيد في الواجهة. هذه القاعدة تسدّها من طرف الخادم.
    await assertFails(deleteDoc(doc(asOther(), 'groups/g1/messages', 'm1')));
  });

  it('صاحب الرسالة يحذف رسالته', async () => {
    await assertSucceeds(
      deleteDoc(doc(asStudent(), 'groups/g1/messages', 'm1'))
    );
  });

  it('المستخدم ينضم للمجموعة (تحديث members)', async () => {
    await assertSucceeds(
      updateDoc(doc(asStudent(), 'groups', 'g1'), { members: [STUDENT] })
    );
  });
});

describe('٦. محتوى المستخدمين — ملكية صريحة ولا تلاعب بحالة المراجعة', () => {
  it('المستخدم يضيف سكناً باسمه', async () => {
    await assertSucceeds(
      setDoc(doc(asStudent(), 'housings', 'h2'), {
        createdBy: STUDENT,
        moderationStatus: 'published',
        name: 'سكن جديد',
      })
    );
  });

  it('لا يستطيع إضافة سكن باسم غيره', async () => {
    await assertFails(
      setDoc(doc(asStudent(), 'housings', 'h3'), {
        createdBy: OTHER,
        moderationStatus: 'published',
        name: 'منتحل',
      })
    );
  });

  it('لا يستطيع إلغاء رفض المشرف بتعديل حالة المراجعة', async () => {
    // السيناريو: المشرف رفض الإعلان، فيحاول صاحبه إعادته إلى «منشور».
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'housings', 'h4'), {
        createdBy: STUDENT,
        moderationStatus: 'rejected',
        name: 'مرفوض',
      });
    });

    await assertFails(
      updateDoc(doc(asStudent(), 'housings', 'h4'), {
        createdBy: STUDENT,
        moderationStatus: 'published',
        name: 'مرفوض',
      })
    );
  });

  it('لا يستطيع إنشاء محتوى بحالة (مرفوض)', async () => {
    await assertFails(
      setDoc(doc(asStudent(), 'housings', 'h5'), {
        createdBy: STUDENT,
        moderationStatus: 'rejected',
        name: 'حالة غير مسموحة',
      })
    );
  });

  it('يستطيع تعديل بيانات إعلانه دون تغيير حالة المراجعة', async () => {
    await assertSucceeds(
      updateDoc(doc(asStudent(), 'housings', 'h1'), { name: 'سكن محدّث' })
    );
  });

  it('المشرف يستطيع رفض الإعلان', async () => {
    await assertSucceeds(
      updateDoc(doc(asAdmin(), 'housings', 'h1'), {
        moderationStatus: 'rejected',
      })
    );
  });

  it('مستخدم آخر لا يحذف إعلاناً ليس له', async () => {
    await assertFails(deleteDoc(doc(asOther(), 'housings', 'h1')));
  });

  it('صاحب الإعلان يحذف إعلانه', async () => {
    await assertSucceeds(deleteDoc(doc(asStudent(), 'housings', 'h1')));
  });

  it('نماذج الاختبارات تتبع نفس قاعدة الملكية بحقل uploadedBy', async () => {
    await assertSucceeds(
      setDoc(doc(asStudent(), 'exam_papers', 'p1'), {
        uploadedBy: STUDENT,
        moderationStatus: 'published',
        title: 'نموذج',
      })
    );
    await assertFails(
      setDoc(doc(asStudent(), 'exam_papers', 'p2'), {
        uploadedBy: OTHER,
        moderationStatus: 'published',
        title: 'منتحل',
      })
    );
  });
});

describe('٧. المشرفون — لا ترقية ذاتية', () => {
  it('المستخدم لا يستطيع منح نفسه صلاحية إدارية', async () => {
    await assertFails(
      setDoc(doc(asStudent(), 'admins', STUDENT), { self: true })
    );
  });

  it('المستخدم لا يقرأ وثيقة مشرف آخر', async () => {
    await assertFails(getDoc(doc(asStudent(), 'admins', ADMIN)));
  });

  it('المشرف يقرأ وثيقته ليعرف صلاحيته', async () => {
    await assertSucceeds(getDoc(doc(asAdmin(), 'admins', ADMIN)));
  });
});

describe('٨. المنع الافتراضي لأي مجموعة غير معرَّفة', () => {
  it('مجموعة غير مذكورة في القواعد ممنوعة تماماً', async () => {
    await assertFails(
      setDoc(doc(asStudent(), 'random_collection', 'x'), { a: 1 })
    );
    await assertFails(getDoc(doc(asAdmin(), 'random_collection', 'x')));
  });
});

describe('٩. ضمانة عدم كسر التطبيق القائم', () => {
  it('كل المجموعات التي يستخدمها التطبيق مقروءة للمستخدم المسجَّل', async () => {
    // هذا الاختبار هو الحارس ضد الخطر الأكبر: نشر قواعد تغطي الجديد فقط
    // فتُغلق المجموعات القائمة ويتعطّل التطبيق عند كل المستخدمين.
    const db = asStudent();
    const collections = [
      ['colleges', 'col_it'],
      ['departments', 'anything'],
      ['courses', 'anything'],
      ['groups', 'g1'],
      ['app_config', 'admission'],
      ['department_guides', 'anything'],
      ['admission_requirements', 'col_it'],
      ['housings', 'h1'],
      ['exam_papers', 'anything'],
    ];

    for (const [collection, id] of collections) {
      await assertSucceeds(getDoc(doc(db, collection, id)));
    }
    assert.ok(true);
  });
});
