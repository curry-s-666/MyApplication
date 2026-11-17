import router from '@ohos.router'
import { UserInfo, getUserById } from '../common/DatabaseUtil'
import { getLoginState, clearLoginState } from '../common/PreferencesUtil'

@Entry
@Component
struct PersonalInfo {
  @StorageLink('theme') currentTheme: string = 'dark'
  @State user: UserInfo = { id: 0, phone: '', nickname: '', avatar: '' }
  @State showQr: boolean = false

  private isDark(): boolean { return this.currentTheme !== 'light' }
  private bgColor(): string { return this.isDark() ? '#1A1A2E' : '#FFFFFF' }
  private textPrimary(): string { return this.isDark() ? '#FFFFFF' : '#111111' }
  private textSecondary(): string { return this.isDark() ? '#888888' : '#999999' }
  private textBody(): string { return this.isDark() ? '#E8E8E8' : '#333333' }
  private surfaceColor(): string { return this.isDark() ? '#353550' : '#F2F3F5' }
  private dividerColor(): string { return this.isDark() ? '#2A2A40' : '#E6E6E6' }
  private cardBg(): string { return this.isDark() ? '#222244' : '#FFFFFF' }
  private sectionGap(): string { return this.isDark() ? '#0A0A18' : '#F2F3F5' }
  @State time: number = 0

  aboutToAppear(): void {
    this.loadUser()
    this.time = new Date().getTime()
    console.log('MyDialog aboutToAppear time:' + this.time)
  }

  onPageShow(): void {
    this.loadUser()
  }

  private async loadUser(): Promise<void> {
    const state = await getLoginState(getContext(this))
    if (state) {
      const user = await getUserById(getContext(this), state.userId)
      if (user) this.user = user
    } else {
      this.user = { id: 0, phone: '', nickname: '', avatar: '' }
      router.back()  // 已注销，自动返回首页
    }
  }

  private async doLogout(): Promise<void> {
    await clearLoginState(getContext(this))
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
          Text('个人信息').fontSize(50).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
          Blank()
          Text('编辑').fontSize(42).fontColor('#E8C575')
            .onClick(() => { router.pushUrl({ url: 'pages/PersonalEdit' }) })
        }
        .width('100%').height(112).padding({ left: 34, right: 34 })

        Column({ space: 18 }) {
          Row() {
            if (this.user.nickname) {
              Text(this.user.nickname.substring(0, 1)).fontSize(68).fontColor('#CCCCCC')
            } else {
              Image($rawfile('person.png')).width(68).height(68).objectFit(ImageFit.Contain)
            }
          }
          .width(156).height(156).borderRadius(78).backgroundColor(this.surfaceColor())
          .justifyContent(FlexAlign.Center)

          Text(this.user.nickname || '未设置昵称')
            .fontSize(52).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)

          Text(this.user.phone || '')
            .fontSize(40).fontColor(this.textSecondary())

          Button('展示二维码')
            .fontSize(42).fontColor('#E8C575').backgroundColor(Color.Transparent)
            .border({ width: 3, color: '#E8C575' }).borderRadius(40).height(80).width(280)
            .onClick(() => {
              this.showQr = true
            })
        }
        .width('100%').padding({ top: 44, bottom: 36 }).alignItems(HorizontalAlign.Center)

        Row() {}.width('100%').height(10).backgroundColor(this.sectionGap())

        Column({ space: 0 }) {
          this.InfoItem('我的收藏')
          this.InfoItem('最近播放')
          this.InfoItem('下载管理')
          Row() {
            Text('账号设置').fontSize(46).fontColor(this.textBody())
            Blank()
            Text('>').fontSize(42).fontColor(this.isDark() ? '#555555' : '#BBBBBB')
          }
          .width('100%').height(112).padding({ left: 34, right: 34 })
          .border({ width: { bottom: 0.5 }, color: this.dividerColor() })
          .onClick(() => { router.pushUrl({ url: 'pages/AccountSettings' }) })
        }.width('100%')

        Row() {}.width('100%').height(10).backgroundColor(this.sectionGap())

        Row() {
          Text('退出登录').fontSize(46).fontColor('#FF6B6B')
        }
        .width('100%').height(112).justifyContent(FlexAlign.Center)
        .onClick(() => { this.doLogout() })

        Blank()
      }
      .width('100%').height('100%').backgroundColor(this.bgColor())

      if (this.showQr) {
        Stack() {
          // 背景遮罩，点击空白区域关闭
          Column()
            .width('100%').height('100%')
            .onClick(() => { this.showQr = false })

          // 二维码卡片
          Column({ space: 28 }) {
            // 返回按钮
            Row() {
              Text('back').fontSize(46).fontColor('#E8C575')
              Blank()
            }.width('100%').height(80)
            .onClick(() => { this.showQr = false })

            Text('二维码').fontSize(50).fontColor(this.textPrimary()).fontWeight(FontWeight.Bold)
            Column() {
              Column({ space: 20 }) {
                QRCode("时间" + this.time + "用户信息" + JSON.stringify(this.user)
                  // 'user:' + this.user.id + ',' + this.user.phone + ',' + this.user.nickname
                ).width(250).height(250).backgroundColor("000000")

                Button("刷新二维码").onClick(() => {
                  this.time = new Date().getTime()
                  console.log("MyDialog onclick 刷新 time:" + this.time)
                })
              }
            }
            .width('100%').alignItems(HorizontalAlign.Center)

            Text(this.user.nickname || '用户').fontSize(40).fontColor(this.textSecondary())
          }
          .width('70%').padding(36).backgroundColor(this.cardBg()).borderRadius(24)
        }
        .width('100%').height('100%').backgroundColor('#99000000')
        .alignContent(Alignment.Center)
      }
    }
    .width('100%').height('100%').backgroundColor(this.bgColor())
  }

  @Builder
  InfoItem(label: string) {
    Row() {
      Text(label).fontSize(46).fontColor(this.textBody())
      Blank()
      Text('>').fontSize(42).fontColor(this.isDark() ? '#555555' : '#BBBBBB')
    }
    .width('100%').height(112).padding({ left: 34, right: 34 })
    .border({ width: { bottom: 0.5 }, color: this.dividerColor() })
  }
}
