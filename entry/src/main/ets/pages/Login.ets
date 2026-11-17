import router from '@ohos.router'
import { loginByPassword, registerUser } from '../common/DatabaseUtil'
import { saveLoginState } from '../common/PreferencesUtil'

@Entry
@Component
struct Login {
  @StorageLink('theme') currentTheme: string = 'dark'
  @State pageMode: number = 0        // 0=登录, 1=注册
  @State phone: string = ''
  @State password: string = ''
  @State confirmPwd: string = ''     // 注册时确认密码
  @State agreed: boolean = false
  @State errorMsg: string = ''

  private isDark(): boolean { return this.currentTheme !== 'light' }
  private bgColor(): string { return this.isDark() ? '#1A1A2E' : '#FFFFFF' }
  private textPrimary(): string { return this.isDark() ? '#E8E8E8' : '#111111' }
  private textSecondary(): string { return this.isDark() ? '#888888' : '#999999' }
  private textHint(): string { return this.isDark() ? '#666666' : '#AAAAAA' }
  private dividerColor(): string { return this.isDark() ? '#2A2A40' : '#E6E6E6' }
  private accentColor(): string { return '#E8C575' }
  // ========== 登录 ==========
  private async doLogin(): Promise<void> {
    if (!this.agreed) { this.errorMsg = '请先同意用户协议'; return }
    if (this.phone.length < 11) { this.errorMsg = '请输入正确的手机号'; return }
    if (this.password.length < 6) { this.errorMsg = '密码至少6位'; return }
    const ctx = getContext(this)
    const res = await loginByPassword(ctx, this.phone, this.password)
    if (res.error) { this.errorMsg = res.error; return }
    if (res.user) {
      await saveLoginState(ctx, res.user.id, res.user.phone, res.user.nickname)
      router.back()
    }
  }

  // ========== 注册 ==========
  private async doRegister(): Promise<void> {
    if (!this.agreed) { this.errorMsg = '请先同意用户协议'; return }
    if (this.phone.length < 11) { this.errorMsg = '请输入正确的手机号'; return }
    if (this.password.length < 6) { this.errorMsg = '密码至少6位'; return }
    if (this.password !== this.confirmPwd) { this.errorMsg = '两次密码不一致'; return }
    const ctx = getContext(this)
    const regRes = await registerUser(ctx, this.phone, this.password)
    if (!regRes.success) { this.errorMsg = regRes.error; return }
    // 注册成功 → 自动登录后返回
    const loginRes = await loginByPassword(ctx, this.phone, this.password)
    if (loginRes.user) {
      await saveLoginState(ctx, loginRes.user.id, loginRes.user.phone, loginRes.user.nickname)
      router.back()
    }
  }

  build() {
    Column() {
      // ===== 顶栏 =====
      Row() {
        Row() {
          Text('exit').fontSize(46).fontColor(this.accentColor())
        }.width(96).height(88).justifyContent(FlexAlign.Center).onClick(() => { router.back() })
        Blank()
        Text(this.pageMode === 0 ? '手机号登录' : '注册账号')
          .fontSize(50).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
        Blank()
        Text('').width(32)
      }.width('100%').height(112).padding({ left: 30, right: 30 })

      // 登录 / 注册 Tab 切换
      Row() {
        Column({ space: 8 }) {
          Text('登录')
            .fontSize(this.pageMode === 0 ? 50 : 40)
            .fontColor(this.pageMode === 0 ? this.textPrimary() : this.textSecondary())
            .fontWeight(this.pageMode === 0 ? FontWeight.Bold : FontWeight.Normal)
            .onClick(() => { this.pageMode = 0; this.errorMsg = '' })
          if (this.pageMode === 0) Row() {}.width(40).height(4).borderRadius(2).backgroundColor(this.accentColor())
        }.width('50%').alignItems(HorizontalAlign.Center)
        Column({ space: 8 }) {
          Text('注册')
            .fontSize(this.pageMode === 1 ? 50 : 40)
            .fontColor(this.pageMode === 1 ? this.textPrimary() : this.textSecondary())
            .fontWeight(this.pageMode === 1 ? FontWeight.Bold : FontWeight.Normal)
            .onClick(() => { this.pageMode = 1; this.errorMsg = '' })
          if (this.pageMode === 1) Row() {}.width(40).height(4).borderRadius(2).backgroundColor(this.accentColor())
        }.width('50%').alignItems(HorizontalAlign.Center)
      }.width('100%').padding({ top: 30 })

      Column({ space: 30 }) {
        // 手机号输入
        Row() {
          Text('+86').fontSize(46).fontColor(this.textPrimary()).padding({ right: 20, top: 12, bottom: 12 })
          Text('>').fontSize(42).fontColor(this.textSecondary()).padding({ right: 26, top: 12, bottom: 12 })
          TextInput({ placeholder: '请输入手机号', text: this.phone })
            .fontSize(46).fontColor(this.textPrimary()).placeholderColor(this.textHint())
            .backgroundColor(Color.Transparent).maxLength(11).type(InputType.Number).layoutWeight(1)
            .height(104).onChange((v: string) => { this.phone = v; this.errorMsg = '' })
        }.width('100%').height(104)
        Row() {}.width('100%').height(1).backgroundColor(this.dividerColor())

        // 密码输入
        Row() {
          TextInput({ placeholder: '请输入密码', text: this.password })
            .fontSize(46).fontColor(this.textPrimary()).placeholderColor(this.textHint())
            .backgroundColor(Color.Transparent).type(InputType.Password).layoutWeight(1)
            .height(104).onChange((v: string) => { this.password = v; this.errorMsg = '' })
        }.width('100%').height(104)
        Row() {}.width('100%').height(1).backgroundColor(this.dividerColor())

        // 注册模式：确认密码
        if (this.pageMode === 1) {
          Row() {
            TextInput({ placeholder: '请确认密码', text: this.confirmPwd })
              .fontSize(46).fontColor(this.textPrimary()).placeholderColor(this.textHint())
              .backgroundColor(Color.Transparent).type(InputType.Password).layoutWeight(1)
              .height(104).onChange((v: string) => { this.confirmPwd = v; this.errorMsg = '' })
          }.width('100%').height(104)
          Row() {}.width('100%').height(1).backgroundColor(this.dividerColor())
        }
      }.width('100%').padding({ left: 36, right: 36, top: 40 })

      // 协议 + 按钮
      Column({ space: 20 }) {
        Row({ space: 10 }) {
          Row() {
            Row() {}
            .width(44).height(44).borderRadius(22)
            .border({ width: 1, color: this.agreed ? this.accentColor() : this.textHint() })
            .backgroundColor(this.agreed ? this.accentColor() : '#00000000')
            .justifyContent(FlexAlign.Center)
          }.width(68).height(68).justifyContent(FlexAlign.Center)
          Text('我已阅读并同意').fontSize(36).fontColor(this.textSecondary())
          Text('《用户协议》').fontSize(36).fontColor(this.accentColor())
        }.width('100%').padding({ top: 8, bottom: 8 })
        .onClick(() => { this.agreed = !this.agreed })
        Button(this.pageMode === 0 ? '登录' : '注册')
          .width('100%').height(104).fontSize(50).fontColor('#333333')
          .backgroundColor(this.accentColor()).borderRadius(52)
          .onClick(() => { if (this.pageMode === 0) this.doLogin(); else this.doRegister() })
        if (this.errorMsg !== '') {
          Text(this.errorMsg).fontSize(36).fontColor('#FF6B6B').width('100%').textAlign(TextAlign.Center)
        }
      }.width('100%').padding({ left: 36, right: 36 }).margin({ top: 56 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgColor())
  }
}
