# The amazing dash-button plugin
module.exports = (env) ->

  Promise = env.require 'bluebird'
  nukiApi = require 'nuki-bridge-api'
  NukiObject = require 'nuki-bridge-api/lib/nuki'
  commons = require('pimatic-plugin-commons')(env)


  # ###NukiPlugin class
  class NukiPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      @debug = @config.debug || false
      @bridge = new nukiApi.Bridge @config.host, @config.port, @config.token
      @base = commons.base @, 'Plugin'

      # register devices
      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("Nuki",
        configDef: deviceConfigDef.Nuki,
        createCallback: (@config, lastState) =>
          new Nuki(@config, @, lastState)
      )

      # auto-discovery
      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-nuki', 'Searching for Nuki Smart Locks.'
        @lastId = null
        @bridge.list().then (nukiDevices) =>
          for device in nukiDevices
            do (device) =>
              @lastId = @base.generateDeviceId @framework, "nuki", @lastId

              deviceConfig =
                id: @lastId
                name: device.name
                class: 'Nuki'
                nukiId: device.nukiId

              @framework.deviceManager.discoveredDevice(
                'pimatic-nuki',
                "#{deviceConfig.name} (#{deviceConfig.nukiId})",
                deviceConfig
              )
      )


  class Nuki extends env.devices.ContactSensor

    constructor: (@config, @plugin, lastState) ->
      @id = @config.id
      @name = @config.name
      @_contact = false
      @nuki = new NukiObject @plugin.bridge, @config.nukiId
      @debug = @plugin.debug || false
      @base = commons.base @, @config.class
      super()
      process.nextTick () =>
        @_requestUpdate()

    destroy: () ->
      @base.cancelUpdate()
      super()

    _requestUpdate: () =>
      @base.cancelUpdate()
      @base.debug "Requesting update"

      @nuki.lockState()
      .then (state) =>
        if typeof state is "string"
          state = parseInt state
        @_setContact (state is nukiApi.lockState.LOCKED)
      .catch (error) =>
        @base.error "Error:", error
      .finally () =>
        @base.scheduleUpdate @_requestUpdate, @interval * 1000, true

    getContact: () -> Promise.resolve @_contact

  # ###Finally
  # Create a instance of my plugin
  # and return it to the framework.
  return new NukiPlugin