$ ->
  Routes.configure ->
    this.get "inbox", "home#inbox"
    this.get "archive", "home#archive"

    this.resource "users", only: [Routes.INDEX]
    this.resource "groups", only: [Routes.INDEX]
    this.resource "resources", only: [Routes.INDEX]
    this.resource "entities", only: [Routes.INDEX]
    this.resource "quote", only: [Routes.INDEX]
    this.resource "places", only: [Routes.INDEX]
    this.resource "deals", only: [Routes.INDEX]
    this.resource "waybills", only: [Routes.INDEX]
    this.resource "allocations", only: [Routes.INDEX]
    this.resource "general_ledger", only: [Routes.INDEX]
    this.resource "balance_sheet", only: [Routes.INDEX]
    this.resource "transcripts", only: [Routes.INDEX]

    this.namespace "documents", ->
      this.resource "users", only: [Routes.NEW, Routes.SHOW]
      this.resource "groups", only: [Routes.NEW, Routes.SHOW]
      this.resource "entities", only: [Routes.NEW, Routes.SHOW]
      this.resource "quote", only: [Routes.NEW, Routes.SHOW]
      this.resource "places", only: [Routes.NEW, Routes.SHOW]
      this.resource "deals", only: [Routes.NEW, Routes.SHOW]
      this.resource "waybills", only: [Routes.NEW, Routes.SHOW]
      this.resource "allocations", only: [Routes.NEW, Routes.SHOW]
      this.resource "money", only: [Routes.NEW, Routes.SHOW]
      this.resource "assets", only: [Routes.NEW, Routes.SHOW]
      this.resource "legal_entities", only: [Routes.NEW, Routes.SHOW]
      this.resource "facts", only: [Routes.NEW, Routes.SHOW]

    this.resource "warehouses", only: [Routes.INDEX], ->
      this.collection "report"
      this.collection "foremen"

    this.resource "helps", only: [Routes.INDEX, Routes.SHOW]
    this.resource "notifications", only: [Routes.INDEX]
    this.resource "settings", only: [Routes.INDEX, Routes.NEW]

    this.namespace "documents", ->
      this.resource "notifications", only: [Routes.NEW, Routes.SHOW]


    this.get "foreman/resources", "foreman#index"

    this.namespace "estimate", ->
      this.resource "bo_ms", only: [Routes.INDEX, Routes.NEW, Routes.SHOW]
      this.resource "prices", only: [Routes.INDEX, Routes.NEW, Routes.SHOW]
      this.resource "catalogs", only: [Routes.INDEX, Routes.NEW, Routes.SHOW]
