// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import ArticleEditorController from "./article_editor_controller.js"
application.register("article-editor", ArticleEditorController)

import FlashController from "./flash_controller.js"
application.register("flash", FlashController)

import HomeHeroController from "./home_hero_controller.js"
application.register("home-hero", HomeHeroController)

import MapController from "./map_controller.js"
application.register("map", MapController)

import MarkdownEditorController from "./markdown_editor_controller.js"
application.register("markdown-editor", MarkdownEditorController)

import RemoteModalController from "./remote_modal_controller.js"
application.register("remote-modal", RemoteModalController)

import TomSelectController from "./tom_select_controller.js"
application.register("tom-select", TomSelectController)

import TooltipsController from "./tooltips_controller.js"
application.register("tooltips", TooltipsController)
