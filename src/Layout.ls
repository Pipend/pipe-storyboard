{Children, DOM:{div}, clone-element, create-class} = require \react

module.exports = create-class do 

    display-name: \Layout

    # get-default-props :: a -> Props
    get-default-props: ->
        class-name: ""
        parameters: {}
        pipe-web-client-end-point: undefined # String
        style: {}

    # render :: a -> ReactElement
    render: ->
        div do
            class-name: "layout #{@props.class-name}"
            style: {} <<< @props.style <<< {display: \flex}
            Children.map do 
                @props.children
                (child) ~> 
                    clone-element do 
                        child
                        parameters: @props.parameters
                        pipe-web-client-end-point: child.props?.pipe-web-client-end-point ? @props.pipe-web-client-end-point