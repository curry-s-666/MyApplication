import preferences from '@ohos.data.preferences';
import type common from '@ohos.app.ability.common';

const PREFERENCES_NAME = 'app_preferences';

async function getPref(ctx: object) {
  return await preferences.getPreferences(ctx as common.Context, PREFERENCES_NAME);
}

// ========== 引导页 ==========
export async function isGuideShown(ctx: object): Promise<boolean> {
  const pref = await getPref(ctx);
  return await pref.get('guide_shown', false) === true;
}

export async function setGuideShown(ctx: object, shown: boolean): Promise<void> {
  const pref = await getPref(ctx);
  await pref.put('guide_shown', shown);
  await pref.flush();
}

// ========== 登录状态 ==========
export async function saveLoginState(ctx: object, userId: number, phone: string, nick: string): Promise<void> {
  const pref = await getPref(ctx);
  await pref.put('is_logged_in', true);
  await pref.put('user_id', userId);
  await pref.put('user_phone', phone);
  await pref.put('user_nick', nick);
  await pref.flush();
}

export async function getLoginState(ctx: object): Promise<{ userId: number, phone: string, nick: string } | null> {
  const pref = await getPref(ctx);
  const loggedIn = await pref.get('is_logged_in', false);
  if (!loggedIn) return null;
  const userId = await pref.get('user_id', 0) as number;
  const phone = await pref.get('user_phone', '') as string;
  const nick = await pref.get('user_nick', '') as string;
  return { userId, phone, nick };
}

export async function clearLoginState(ctx: object): Promise<void> {
  const pref = await getPref(ctx);
  await pref.put('is_logged_in', false);
  await pref.flush();
}

// ========== 主题 ==========
export async function saveTheme(ctx: object, theme: string): Promise<void> {
  const pref = await getPref(ctx);
  await pref.put('app_theme', theme);
  await pref.flush();
}

export async function loadTheme(ctx: object): Promise<string> {
  const pref = await getPref(ctx);
  const theme = await pref.get('app_theme', 'dark') as string;
  return theme;
}
