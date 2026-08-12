export interface QuestDefinition {
  id: string;
  type: 'daily' | 'weekly';
  titleKey: string;
  descriptionKey: string;
  section: string;
  pointsValue: number;
  targetCount: number;
  actionType: string;
  isActive: boolean;
}

export const DEFAULT_DAILY_QUESTS: QuestDefinition[] = [
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

export const DEFAULT_WEEKLY_QUESTS: QuestDefinition[] = [
  {
    id: 'weekly_5_days',
    type: 'weekly',
    titleKey: 'quests.weekly_5_days_title',
    descriptionKey: 'quests.weekly_5_days_desc',
    section: 'home',
    pointsValue: 50,
    targetCount: 5,
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
    actionType: 'receive_like',
    isActive: true,
  },
];

export const LEADERBOARD_TIERS = ['bronze', 'silver', 'gold', 'platinum', 'diamond'] as const;
export type LeaderboardTier = typeof LEADERBOARD_TIERS[number];

export const LEADERBOARD_CONFIG = {
  GROUP_MIN_SIZE: 20,
  GROUP_MAX_SIZE: 30,
  PROMOTION_COUNT: 7,
  DEMOTION_COUNT: 5,
};
