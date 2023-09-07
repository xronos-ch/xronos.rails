// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import ArticleEditorController from "./article_editor_controller"
application.register("article-editor", ArticleEditorController)

import FlashController from "./flash_controller"
application.register("flash", FlashController)

import HomeHeroController from "./home_hero_controller"
application.register("home-hero", HomeHeroController)

import MapController from "./map_controller"
application.register("map", MapController)

import MarkdownEditorController from "./markdown_editor_controller"
application.register("markdown-editor", MarkdownEditorController)

import RemoteModalController from "./remote_modal_controller"
application.register("remote-modal", RemoteModalController)

import SliderController from "./slider_controller"
application.register("slider", SliderController)

import TomSelectController from "./tom_select_controller"
application.register("tom-select", TomSelectController)

import TooltipsController from "./tooltips_controller"
application.register("tooltips", TooltipsController)

import VegaController from "./vega_controller"
application.register("vega", VegaController)
