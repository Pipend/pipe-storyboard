{create-class, DOM:{div, label}} = require \react

module.exports = create-class do 

  # get-default-props :: () -> Props
  get-default-props: ->
    class-name: ""
    label: ""
    # render :: () -> ReactElement
    show-label: true
    style: {}

  # render :: () -> ReactElement
  render: ->
    div do 
      class-name: "labelled-component #{@props.class-name}"
      style: @props.style

      # LABEL
      if @props.show-label
        label null, @props.label

      # CUSTOM COMPONENT
      @props.render!
        