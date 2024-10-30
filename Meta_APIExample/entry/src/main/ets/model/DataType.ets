import { ORIENTATION_MODE, VideoDimensions } from 'meta_rtc_sdk'

export interface ExampleCategory{
  title: Resource,
  childNodes: ExampleItem[]
}

export interface ExampleItem{
  title: Resource,
  url: string
}

export interface SettingsInfo {
  dimensions: VideoDimensions,
  frameRate: number,
  orientationMode: ORIENTATION_MODE
}