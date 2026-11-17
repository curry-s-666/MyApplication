import router from '@ohos.router'
import { updateUser, getUserById } from '../common/DatabaseUtil'
import { getLoginState, saveLoginState } from '../common/PreferencesUtil'

@Entry
@Component
struct PersonalEdit {
  @StorageLink('theme') currentTheme: string = 'dark'
  @State nickname: string = ''
  @State saved: boolean = false

  private isDark(): boolean { return this.currentTheme !== 'light' }
  private bgColor(): string { return this.isDark() ? '#1A1A2E' : '#FFFFFF' }
  private textPrimary(): string { return this.isDark() ? '#FFFFFF' : '#111111' }
  private textSecondary(): string { return this.isDark() ? '#888888' : '#999999' }
  private surfaceColor(): string { return this.isDark() ? '#353550' : '#F2F3F5' }
  private dividerColor(): string { return this.isDark() ? '#2A2A40' : '#E6E6E6' }
  private userId: number = 0

  aboutToAppear(): void {
    this.loadData()
  }

  private async loadData(): Promise<void> {
    const state = await getLoginState(getContext(this))
    if (state) {
      this.userId = state.userId
      const user = await getUserById(getContext(this), state.userId)
      if (user) this.nickname = user.nickname
    }
  }

  private async doSave(): Promise<void> {
    if (!this.nickname.trim()) return
    await updateUser(getContext(this), this.userId, this.nickname.trim(), '')
    const state = await getLoginState(getContext(this))
    if (state) {
      await saveLoginState(getContext(this), state.userId, state.phone, this.nickname.trim())
    }
    this.saved = true
    setTimeout(() => { router.back() }, 800)
  }

  build() {
    Column({ space: 0 }) {
      Row() {
        Text('back').fontSize(46).fontColor('#E8C575').onClick(() => { router.back() })
        Blank()
        Text('编辑资料').fontSize(50).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
        Blank()
        Text('保存').fontSize(42).fontColor('#E8C575').onClick(() => { this.doSave() })
      }
      .width('100%').height(112).padding({ left: 34, right: 34 })

      Column({ space: 14 }) {
        Row() {
          if (this.nickname) {
            Text(this.nickname.substring(0, 1)).fontSize(68).fontColor('#CCCCCC')
          } else {
            Image($rawfile('person.png')).width(68).height(68).objectFit(ImageFit.Contain)
          }
        }
        .width(156).height(156).borderRadius(78).backgroundColor(this.surfaceColor())
        .justifyContent(FlexAlign.Center)

        Text('更换头像').fontSize(40).fontColor('#E8C575')
      }
      .width('100%').padding({ top: 36, bottom: 36 }).alignItems(HorizontalAlign.Center)

      Row() {
        Text('昵称').fontSize(46).fontColor(this.textSecondary()).width(150)
        TextInput({ placeholder: '请输入昵称', text: this.nickname })
          .fontSize(46).fontColor(this.textPrimary()).placeholderColor('#555555')
          .backgroundColor(Color.Transparent).layoutWeight(1)
          .onChange((v: string) => { this.nickname = v })
      }
      .width('100%').height(116).padding({ left: 34, right: 34 })
      .border({ width: { bottom: 0.5 }, color: this.dividerColor() })

      if (this.saved) {
        Text('保存成功').fontSize(42).fontColor('#4CAF50').margin({ top: 40 })
      }
    }
    .width('100%').height('100%').backgroundColor(this.bgColor())
  }
}
