import type common from '@ohos.app.ability.common'

class AppContext {
  private _ctx: common.UIAbilityContext | null = null
  private static instance: AppContext

  static getInstance(): AppContext {
    if (!AppContext.instance) {
      AppContext.instance = new AppContext()
    }
    return AppContext.instance
  }

  set(ctx: common.UIAbilityContext): void {
    this._ctx = ctx
  }

  get(): common.UIAbilityContext | null {
    return this._ctx
  }
}

export const appCtx = AppContext.getInstance()
