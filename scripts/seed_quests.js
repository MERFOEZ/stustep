/**
 * Standalone Firebase Admin Script to seed default quests into Firestore.
 * Usage:
 *   node scripts/seed_quests.js
 */

const admin = require('firebase-admin');

if (!admin.apps.length) {
  try {
    admin.initializeApp({
      projectId: 'stustep-4c1ea',
    });
  } catch (e) {
    admin.initializeApp();
  }
}

const db = admin.firestore();

const DEFAULT_DAILY_QUESTS = [
  {
    id: 'daily_lesson',
    type: 'daily',
    titleKey: 'quests.daily_lesson_title',
    descriptionKey: 'quests.daily_lesson_desc',
    section: 'courses',
    pointsValue: 15,
    targetCount: 1,
    actionType: 'complete_lesson',
    isActive: true,
  },
  {
    id: 'daily_ai_chat',
    type: 'daily',
    titleKey: 'quests.daily_ai_title',
    descriptionKey: 'quests.daily_ai_desc',
    section: 'ai_chat',
    pointsValue: 15,
    targetCount: 1,
    actionType: 'ai_chat_session',
    isActive: true,
  },
  {
    id: 'daily_quiz',
    type: 'daily',
    titleKey: 'quests.daily_quiz_title',
    descriptionKey: 'quests.daily_quiz_desc',
    section: 'academic_tools',
    pointsValue: 10,
    targetCount: 1,
    actionType: 'pass_quiz',
    isActive: true,
  },
  {
    id: 'daily_community',
    type: 'daily',
    titleKey: 'quests.daily_community_title',
    descriptionKey: 'quests.daily_community_desc',
    section: 'groups',
    pointsValue: 10,
    targetCount: 1,
    actionType: 'community_interaction',
    isActive: true,
  },
  {
    id: 'daily_login',
    type: 'daily',
    titleKey: 'quests.daily_login_title',
    descriptionKey: 'quests.daily_login_desc',
    section: 'home',
    pointsValue: 5,
    targetCount: 1,
    actionType: 'daily_login',
    isActive: true,
  },
];

const DEFAULT_WEEKLY_QUESTS = [
  {
    id: 'weekly_5_days',
    type: 'weekly',
    titleKey: 'quests.weekly_5_days_title',
    descriptionKey: 'quests.weekly_5_days_desc',
    section: 'home',
    pointsValue: 50,
    targetCount: 5,
    targetValue: 5,
    actionType: 'daily_login',
    isActive: true,
  },
  {
    id: 'weekly_course_complete',
    type: 'weekly',
    titleKey: 'quests.weekly_course_title',
    descriptionKey: 'quests.weekly_course_desc',
    section: 'courses',
    pointsValue: 80,
    targetCount: 1,
    targetValue: 1,
    actionType: 'complete_course',
    isActive: true,
  },
  {
    id: 'weekly_3_sections',
    type: 'weekly',
    titleKey: 'quests.weekly_sections_title',
    descriptionKey: 'quests.weekly_sections_desc',
    section: 'home',
    pointsValue: 40,
    targetCount: 3,
    targetValue: 3,
    actionType: 'use_section',
    isActive: true,
  },
  {
    id: 'weekly_10_likes',
    type: 'weekly',
    titleKey: 'quests.weekly_likes_title',
    descriptionKey: 'quests.weekly_likes_desc',
    section: 'groups',
    pointsValue: 30,
    targetCount: 10,
    targetValue: 10,
    actionType: 'receive_like',
    isActive: true,
  },
];

async function seedQuests() {
  console.log('🚀 Seeding default quests into Firestore...');
  const batch = db.batch();

  for (const quest of DEFAULT_DAILY_QUESTS) {
    const ref = db.collection('dailyQuests').doc(quest.id);
    batch.set(ref, quest, { merge: true });
    console.log(` ✅ Added daily quest: ${quest.id} (${quest.pointsValue} pts)`);
  }

  for (const quest of DEFAULT_WEEKLY_QUESTS) {
    const ref = db.collection('weeklyQuests').doc(quest.id);
    batch.set(ref, quest, { merge: true });
    console.log(` ✅ Added weekly quest: ${quest.id} (${quest.pointsValue} pts)`);
  }

  await batch.commit();
  console.log('✨ Default quests successfully seeded into Firestore!');
}

seedQuests().catch(console.error);
