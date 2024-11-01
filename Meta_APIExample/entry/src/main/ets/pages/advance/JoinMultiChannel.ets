import {
  ChannelMediaOptions,
  Constants,
  IRtcEngineEventHandler,IRtcChannelEventHandler,
  RtcEngine,
  RtcEngineConfig,
  RtcEngineEx,
  VideoCanvas,
  RtcChannel,
  VideoEncoderConfiguration,
} from 'meta_rtc_sdk';
import { TitleBar } from '../../common/TitleBar';
import Logger from '../../util/Logger';
import { common } from '@kit.AbilityKit';
import { AppID } from '../../common/KeyCenter';
import ShowToast from '../../util/ShowToast';
import PermissionHelper from '../../util/PermissionHelper';
import { GlobalInfo } from '../Data';

const TAG = 'JoinMultiChannel'

@Entry
@Component
struct JoinMultiChannel {
  private rtcEngine: RtcEngineEx | undefined = undefined;
  @State mainChannelName: string = ''
  @State exChannelName: string = ''
  @State exChannel: RtcChannel | undefined | null = null;
  @State isMainJoined: boolean = false
  @State isExJoined: boolean = false
  @State exRemoteUid: number = 0
  @State mainRemoteUid: number = 0
  @State mainLocalUid: number = 0
  @State exLocalUid: number = 0

  aboutToAppear(): void {
    Logger.info(TAG, 'aboutToAppear')
    let config: RtcEngineConfig = new RtcEngineConfig();
    let context = getContext(this) as common.UIAbilityContext;
    config.mAppId = AppID;
    config.mEventHandler = {};
    config.mEventHandler.onUserJoined = (uid: number, collapse: number) => {
      Logger.info(TAG, "mEventHandler.onUserJoined: " + uid + " , " + collapse);
      if (this.mainRemoteUid == 0) {
        this.mainRemoteUid = uid
      }
    };
    config.mEventHandler.onUserOffline = (uid: number, reason: number) => {
      Logger.info(TAG, "mEventHandler.onUserOffline: " + uid + " , " + reason)
      if (this.mainRemoteUid == uid) {
        this.mainRemoteUid = 0
      }
    };
    config.mEventHandler.onJoinChannelSuccess = (cid: string, uid: number, elapsed: number) => {
      Logger.info(TAG, "mEventHandler.onJoinChannelSuccess: " + uid);
      this.isMainJoined = true
      this.mainLocalUid = uid
    }
    config.mEventHandler.onLeaveChannel = () => {
      Logger.info(TAG, "mEventHandler.onLeaveChannel");
      this.isMainJoined = false
      this.mainLocalUid = 0
      this.mainRemoteUid = 0
    }
    config.mEventHandler.onError = (err: number, message: string) => {
      Logger.info(TAG, "mEventHandler.onError: " + err + " message " + message);
      ShowToast.longToast("onError " + err + " : " + message)
    }
    config.mContext = context;
    Logger.info(TAG, "in thread create engine begin: ");
    this.rtcEngine = RtcEngine.create(config) as RtcEngineEx;
    let encoderConfig = new VideoEncoderConfiguration()
    encoderConfig.dimensions = GlobalInfo.settings.dimensions
    encoderConfig.frameRate = GlobalInfo.settings.frameRate
    encoderConfig.orientationMode = GlobalInfo.settings.orientationMode
    this.rtcEngine.setVideoEncoderConfiguration(encoderConfig)
    this.rtcEngine.enableVideo()
  }

  aboutToDisappear(): void {
    if (this.rtcEngine != undefined) {
      if (this.isMainJoined) {
        if (this.isExJoined) {
          this.leaveExChannel()
        }
        this.rtcEngine.stopPreview();
        this.rtcEngine.leaveChannel();
      }
      Logger.info(TAG, "destroy begin")
      RtcEngine.destroy();
      Logger.info(TAG, "destroy end")
      this.rtcEngine = undefined;
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      TitleBar({
        title: $r('app.string.item_joinmultichannel'),
        showBack: true
      }).flexGrow(0)

      Column() {
        Row() {
          if (this.mainLocalUid != 0) {
            XComponent({
              id: 'preview_local',
              type: 'surface',
              libraryname: Constants.META_LIB_NAME,
            }).onLoad(() => {
              let localCanvas = new VideoCanvas("preview_local");
              localCanvas.uid = this.mainLocalUid;
              localCanvas.renderMode = VideoCanvas.RENDER_MODE_HIDDEN;
              localCanvas.mirrorMode = 0;
              this.rtcEngine?.setupLocalVideo(localCanvas);
            }).width('50%')
          }

          if (this.mainRemoteUid != 0) {
            XComponent({
              id: 'preview_remote',
              type: 'surface',
              libraryname: Constants.META_LIB_NAME,
            }).onLoad(() => {
              let localCanvas = new VideoCanvas("preview_remote");
              localCanvas.uid = this.mainRemoteUid;
              localCanvas.renderMode = VideoCanvas.RENDER_MODE_HIDDEN;
              localCanvas.mirrorMode = 0;
              this.rtcEngine?.setupRemoteVideo(localCanvas);
            }).width('50%')
          }
        }
        .align(Alignment.TopStart)
        .height("50%")
        .width('100%')

        Row() {
          if (this.exRemoteUid != 0) {
            XComponent({
              id: 'preview_remote_ex',
              type: 'surface',
              libraryname: Constants.META_LIB_NAME,
            }).onLoad(() => {

              let localCanvas = new VideoCanvas("preview_remote_ex");
              localCanvas.channelId = this.exChannelName;
              localCanvas.uid = this.exRemoteUid;
              localCanvas.renderMode = VideoCanvas.RENDER_MODE_HIDDEN;
              localCanvas.mirrorMode = 0;
              this.rtcEngine?.setupRemoteVideo(localCanvas);
            }).width('100%')
          }
        }
        .align(Alignment.TopStart)
        .height("50%")
        .width('100%')
      }
      .align(Alignment.TopStart)
      .flexGrow(1)

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text($r('app.string.ex_channel_name')).flexGrow(0)
        Text(": ").flexGrow(0)
        Text(this.exChannelName).flexGrow(1).margin({ right: 6 })
        if (this.isExJoined) {
          Button($r('app.string.leave'))
            .enabled(this.isMainJoined)
            .onClick(() => {
              this.leaveExChannel();
            })
            .flexGrow(0)
        } else {
          Button($r('app.string.join'))
            .enabled(this.isMainJoined)
            .onClick(() => {
              this.joinExChannel()
            })
            .flexGrow(0)
        }
      }
      .flexGrow(0)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        TextInput({ placeholder: $r('app.string.text_input_channel_name') })
          .enabled(!this.isMainJoined)
          .onChange((value) => {
            this.mainChannelName = value
            this.exChannelName = value + '-2'
          })
          .enableKeyboardOnFocus(false)
          .flexGrow(1)
          .margin({ right: 6 })

        if (this.isMainJoined) {
          Button($r('app.string.leave'))
            .onClick(() => {
              if (this.isExJoined) {
                this.leaveExChannel()
              }
              this.rtcEngine?.stopPreview()
              this.rtcEngine?.leaveChannel()
            })
            .flexGrow(0)
        } else {
          Button($r('app.string.join'))
            .onClick(async () => {
              if (this.mainChannelName == "") {
                ShowToast.shortToast("The channel name is empty!")
                return
              }
              if (!(await PermissionHelper.checkPermissions(
                getContext(this) as common.UIAbilityContext,
                ['ohos.permission.MICROPHONE', 'ohos.permission.CAMERA']
              ))) {
                ShowToast.shortToast("Permission leak!")
                return
              }
              this.rtcEngine?.setChannelProfile(Constants.ChannelProfile.LIVE_BROADCASTING);
              this.rtcEngine?.setClientRole(Constants.ClientRole.CLIENT_ROLE_BROADCASTER);
              Logger.info(TAG, "start join main Channel : " + this.mainChannelName);
              let ret = this.rtcEngine?.joinChannel('', this.mainChannelName, '', 0)
              if (ret != Constants.ErrorCode.ERR_OK) {
                ShowToast.longToast("joinChannelWithOptions error " + ret + " : " + RtcEngine.getErrorDescription(ret))
                return
              }

              this.rtcEngine?.startPreview()
              this.joinExChannel()
              focusControl.requestFocus("button_to_join")
            })
            .flexGrow(0)
        }
      }
      .height(60)
      .flexGrow(0)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    }
    .backgroundColor($r('app.color.background_shallow_grey'))
  }

  private leaveExChannel() {
    Logger.info(TAG, "start leaveExChannel : " + this.exChannelName + " ex_uid: " + this.exLocalUid);
    let ret = this.exChannel?.leaveChannel();
    this.exChannel?.destroy();
    if (ret == 0) {
      this.isExJoined = false;
      this.exLocalUid = 0;
      this.exRemoteUid = 0;
    } else {
      ShowToast.shortToast("LeaveChannelEx error: " + ret);
    }
  }

  private async joinExChannel() {
    this.exLocalUid = Math.round(Math.random() * 1000) + 10000;
    Logger.info(TAG, "start joinExChannel : " + this.exChannelName + " ex_uid: " + this.exLocalUid);
    this.exChannel = this.rtcEngine?.createRtcChannel(this.exChannelName);
    let exEventHandler: IRtcChannelEventHandler = {};
    exEventHandler.onJoinChannelSuccess = () => {
      Logger.info(TAG, "mExEventHandler.onJoinChannelSuccess");
      this.isExJoined = true;
    };
    exEventHandler.onLeaveChannel = () => {
      this.isExJoined = false;
      this.exLocalUid = 0;
      this.exRemoteUid = 0;
    };
    exEventHandler.onUserJoined = (rtcChannel: RtcChannel, uid: number, collapse: number) => {
      Logger.info(TAG, "mExEventHandler.onUserJoined: " + uid );
      if (this.exRemoteUid == 0) {
        this.exRemoteUid = uid;
      }
    };
    exEventHandler.onUserOffline = (rtcChannel: RtcChannel, uid: number, reason: number) => {
      Logger.info(TAG, "mExEventHandler.onUserJoined: " + uid + " , reason:" + reason);
      if (this.exRemoteUid == uid) {
        this.exRemoteUid = 0;
      }
    };

    this.exChannel?.setRtcChannelEventHandler(exEventHandler);

    let exMediaOption: ChannelMediaOptions = new ChannelMediaOptions();
    exMediaOption.autoSubscribeVideo = true;
    exMediaOption.autoSubscribeAudio = true;
    exMediaOption.autoPublishLocalVideo = false;
    exMediaOption.autoPublishLocalAudio = false;
    this.exChannel?.setClientRole(Constants.ClientRole.CLIENT_ROLE_AUDIENCE);
    let ret = this.exChannel?.joinChannel('', '', this.exLocalUid, exMediaOption);
    if (ret != Constants.ErrorCode.ERR_OK) {
      ShowToast.longToast("joinChannelEx error " + ret + " : " + RtcEngine.getErrorDescription(ret))
      return
    }
  }
}