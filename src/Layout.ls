{Children, DOM:{div}, clone-element, create-class} = require \react

module.exports = create-class do 

    display-name: \Layout

    # get-default-props :: a -> Props
    get-default-props: ->
        cache: undefined # Boolean
        class-name: ""
        parameters: {}
        style: {}
        url: undefined # String

    # render :: a -> ReactElement
    render: ->
        div do
            class-name: "layout #{@props.class-name}"
            style: {} <<< @props.style <<< {display: \flex}

            # CHILDREN
            Children.map do 
                @props.children
                (child) ~> 

                    # STORY | LAYOUT
                    clone-element do 
                        child
                        cache: child.props?.cache ? @props.cache
                        parameters: @props.parameters
                        url: child.props?.url ? @props.url

    