import router from '@ohos.router'
import { UserInfo, deleteUser, changePassword, queryUser } from '../common/DatabaseUtil'
import { getLoginState, clearLoginState } from '../common/PreferencesUtil'

@Entry
@Component
struct AccountSettings {
  @StorageLink('theme') currentTheme: string = 'dark'
  @State user: UserInfo = { id: 0, phone: '', nickname: '', avatar: '' }
  @State showChangePwd: boolean = false
  @State oldPwd: string = ''
  @State newPwd: string = ''
  @State changePwdMsg: string = ''
  @State showQuery: boolean = false
  @State queryPhone: string = ''
  @State queriedUser: UserInfo | null = null
  @State queryMsg: string = ''
  @State showDeleteConfirm: boolean = false

  private isDark(): boolean { return this.currentTheme !== 'light' }
  private bgColor(): string { return this.isDark() ? '#1A1A2E' : '#FFFFFF' }
  private textPrimary(): string { return this.isDark() ? '#FFFFFF' : '#111111' }
  private textSecondary(): string { return this.isDark() ? '#888888' : '#999999' }
  private textBody(): string { return this.isDark() ? '#E8E8E8' : '#333333' }
  private surfaceColor(): string { return this.isDark() ? '#353550' : '#F2F3F5' }
  private dividerColor(): string { return this.isDark() ? '#2A2A40' : '#E6E6E6' }
  private sectionGap(): string { return this.isDark() ? '#0A0A18' : '#F2F3F5' }
  private cardBg(): string { return this.isDark() ? '#252540' : '#F2F3F5' }

  aboutToAppear(): void { this.loadUser() }
  onPageShow(): void { this.loadUser() }

  private async loadUser(): Promise<void> {
    const state = await getLoginState(getContext(this))
    if (state) { this.user = { id: state.userId, phone: state.phone, nickname: state.nick, avatar: '' } }
  }

  private async doQuery(): Promise<void> {
    if (this.queryPhone.length < 11) { this.queryMsg = '请输入正确的手机号'; return }
    const ctx = getContext(this)
    const res = await queryUser(ctx, this.queryPhone)
    if (res.error) { this.queryMsg = res.error; this.queriedUser = null; return }
    this.queriedUser = res.user; this.queryMsg = ''
  }

  private async doChangePwd(): Promise<void> {
    if (this.oldPwd.length < 6 || this.newPwd.length < 6) { this.changePwdMsg = '密码至少6位'; return }
    const ctx = getContext(this)
    const res = await changePassword(ctx, this.user.phone, this.oldPwd, this.newPwd)
    if (!res.success) { this.changePwdMsg = res.error; return }
    this.changePwdMsg = '密码修改成功'; this.oldPwd = ''; this.newPwd = ''
  }

  private async doDelete(): Promise<void> {
    const ctx = getContext(this)
    const res = await deleteUser(ctx, this.user.phone)
    if (!res.success) { this.changePwdMsg = res.error; return }
    await clearLoginState(ctx)
    router.back()
  }

  build() {
    Stack() {
      Column({ space: 0 }) {
        Row() {
          Row() {
            Text('back').fontSize(46).fontColor('#E8C575')
          }.padding({ left: 4, right: 16, top: 12, bottom: 12 }).onClick(() => { router.back() })
          Blank()
          Text('账号设置').fontSize(50).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
          Blank(); Text('').width(32)
        }.width('100%').height(112).padding({ left: 34, right: 34 })

        Column({ space: 10 }) {
          Row() {
            Text(this.user.nickname ? this.user.nickname.substring(0, 1) : '')
              .fontSize(68).fontColor('#CCCCCC')
          }.width(132).height(132).borderRadius(66).backgroundColor(this.surfaceColor()).justifyContent(FlexAlign.Center)
          Text(this.user.nickname || '未设置昵称').fontSize(48).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
          Text('手机号：' + this.user.phone).fontSize(38).fontColor(this.textSecondary())
        }.width('100%').padding({ top: 30, bottom: 30 }).alignItems(HorizontalAlign.Center)

        Row() {}.width('100%').height(10).backgroundColor(this.sectionGap())

        Column({ space: 0 }) {
          this.SectionHeader('查询账号', () => { this.showQuery = !this.showQuery })
          if (this.showQuery) {
            Column({ space: 12 }) {
              Row({ space: 10 }) {
                TextInput({ placeholder: '输入手机号查询', text: this.queryPhone })
                  .fontSize(40).fontColor(this.textPrimary()).placeholderColor('#666666')
                  .backgroundColor(this.isDark() ? '#25FFFFFF' : '#1A000000').maxLength(11).type(InputType.Number).layoutWeight(1)
                  .onChange((v: string) => { this.queryPhone = v })
                Button('查询').fontSize(36).fontColor('#333333').backgroundColor('#E8C575')
                  .borderRadius(32).height(76).padding({ left: 24, right: 24 }).onClick(() => { this.doQuery() })
              }.width('100%')
              if (this.queryMsg !== '') { Text(this.queryMsg).fontSize(32).fontColor('#FF6B6B') }
              if (this.queriedUser) {
                Column({ space: 6 }) {
                  Text('昵称：' + this.queriedUser.nickname).fontSize(36).fontColor(this.textSecondary())
                  Text('手机号：' + this.queriedUser.phone).fontSize(36).fontColor(this.textSecondary())
                }.width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(10)
              }
            }.width('100%').padding({ left: 24, right: 24, top: 12, bottom: 16 })
          }
        }.width('100%')

        Column({ space: 0 }) {
          this.SectionHeader('修改密码', () => { this.showChangePwd = !this.showChangePwd })
          if (this.showChangePwd) {
            Column({ space: 12 }) {
              TextInput({ placeholder: '请输入旧密码', text: this.oldPwd })
                .fontSize(40).fontColor(this.textPrimary()).placeholderColor('#666666')
                .backgroundColor(this.isDark() ? '#25FFFFFF' : '#1A000000').type(InputType.Password).width('100%')
                .onChange((v: string) => { this.oldPwd = v })
              TextInput({ placeholder: '请输入新密码', text: this.newPwd })
                .fontSize(40).fontColor(this.textPrimary()).placeholderColor('#666666')
                .backgroundColor(this.isDark() ? '#25FFFFFF' : '#1A000000').type(InputType.Password).width('100%')
                .onChange((v: string) => { this.newPwd = v })
              Button('确认修改').fontSize(40).fontColor('#333333').backgroundColor('#E8C575')
                .borderRadius(42).width('100%').height(84).onClick(() => { this.doChangePwd() })
              if (this.changePwdMsg !== '') {
                Text(this.changePwdMsg).fontSize(32)
                  .fontColor(this.changePwdMsg.includes('成功') ? '#E8C575' : '#FF6B6B')
              }
            }.width('100%').padding({ left: 24, right: 24, top: 12, bottom: 16 })
          }
        }.width('100%')

        Row() {
          Text('注销账号').fontSize(46).fontColor('#FF6B6B')
        }.width('100%').height(112).padding({ left: 34, right: 34 }).justifyContent(FlexAlign.Start)
        .border({ width: { bottom: 0.5 }, color: this.dividerColor() }).onClick(() => { this.showDeleteConfirm = true })

        Blank()
      }.width('100%').height('100%').backgroundColor(this.bgColor())

      if (this.showDeleteConfirm) {
        Column() {
          Column({ space: 24 }) {
            Text('确认注销').fontSize(48).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
            Text('注销后数据将无法恢复，确定要注销账号吗？')
              .fontSize(36).fontColor(this.textSecondary()).textAlign(TextAlign.Center)
            Row({ space: 20 }) {
              Button('取消').fontSize(40).fontColor(this.isDark() ? '#888888' : '#999999')
                .backgroundColor(this.surfaceColor()).borderRadius(42).width('40%').height(84)
                .onClick(() => { this.showDeleteConfirm = false })
              Button('确认注销').fontSize(40).fontColor('#FFFFFF')
                .backgroundColor('#FF6B6B').borderRadius(42).width('40%').height(84)
                .onClick(() => { this.doDelete() })
            }.width('100%').justifyContent(FlexAlign.Center)
          }.width('75%').padding(32).backgroundColor(this.cardBg()).borderRadius(20)
        }
        .width('100%').height('100%').backgroundColor('#99000000')
        .justifyContent(FlexAlign.Center).onClick(() => { this.showDeleteConfirm = false })
      }
    }
    .width('100%').height('100%').backgroundColor(this.bgColor())
  }

  @Builder
  SectionHeader(title: string, onClick: () => void) {
    Row() {
      Text(title).fontSize(46).fontColor(this.textBody())
      Blank()
      Text('>').fontSize(42).fontColor(this.isDark() ? '#555555' : '#BBBBBB')
    }
    .width('100%').height(112).padding({ left: 34, right: 34 })
    .border({ width: { bottom: 0.5 }, color: this.dividerColor() })
    .onClick(onClick)
  }
}
