require! \moment
{map} = require \prelude-ls
{{div, input, label}:DOM, create-class, create-factory} = require \react
{render} = require \react-dom
require! \react-selectize
SimpleSelect = create-factory react-selectize.SimpleSelect
LabelledComponent = create-factory (require \../../src/index.ls).LabelledComponent

module.exports = create-class do 

  display-name: \DateRange

  # get-default-props :: () -> Props
  get-default-props: ->
    ago: ""
    from: ""
    to: ""

  # render :: a -> ReactElement
  render: ->
    div do 
      class-name: \date-range
      
      # AGO      
      LabelledComponent do 
        label: \Ago
        SimpleSelect do 
          value: 
            label: @props.ago
            value: @props.ago
          options: ['1 day', '1 week', '1 month', '3 months', 'custom'] |> map ~> label: it, value: it
          on-value-change: ({value}?) ~>
            @props.on-change ago: value

      if @props.ago == \custom

        # FROM & TO
        div do 
          null
          <[from to]> |> map (p) ~>
            LabelledComponent do
              key: p
              class-name: p
              label: p
              input do 
                type: \datetime-local
                value: @props[p]
                on-change: ({target:{value}}) ~>
                  @props.on-change "#{p}" : value
