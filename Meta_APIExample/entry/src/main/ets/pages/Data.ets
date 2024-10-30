import { ORIENTATION_MODE, VideoDimensions } from 'meta_rtc_sdk'
import { ExampleCategory, ExampleItem, SettingsInfo } from '../model/DataType'

export const BASIC_ITEMS: ExampleItem[] =
  [
    {
      title: $r('app.string.item_joinvideochannel'),
      url: 'pages/basic/JoinVideoChannel'
    },
    {
      title: $r('app.string.item_joinaudiochannel'),
      url: 'pages/basic/JoinAudioChannel'
    }
  ]

export const ADVANCE_ITEMS: ExampleItem[] =
  [
    {
      title: $r('app.string.item_livestreaming'),
      url: 'pages/advance/LiveStreaming'
    },
    {
      title: $r('app.string.item_joinmultichannel'),
      url: 'pages/advance/JoinMultiChannel'
    },
    {
      title: $r('app.string.item_playaudiofiles'),
      url: 'pages/advance/PlayAudioFiles'
    }
  ]

export const COLLECTION_CATEGORIES: ExampleCategory[] =
  [
    {
      childNodes: BASIC_ITEMS,
      title: $r('app.string.category_basic')
    },
    {
      childNodes: ADVANCE_ITEMS,
      title: $r("app.string.category_advanced")
    },
  ]

export class GlobalInfo {
  static settings: SettingsInfo = {
    dimensions: new VideoDimensions(960, 540),
    frameRate: 15,
    orientationMode: ORIENTATION_MODE.ORIENTATION_MODE_ADAPTIVE
  }
}