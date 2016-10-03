module.exports = {
  title: "pimatic-nuki device config schemas"
  Nuki:
    title: "Nuki Smart Lock config"
    type: "object"
    extensions: ["xLink"]
    properties: {
      nukiId:
        description: "The id of the Nuki Smartlock from which the lock state should be retrieved"
        type: "number"
      interval:
        description: "The time interval in seconds (minimum 10) at which lock state shall be read"
        type: "number"
        default: 30
        minimum: 10
    }
}