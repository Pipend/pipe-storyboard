prefixer = new (require \inline-style-prefixer)!
{id} = require \prelude-ls
{Children, DOM:{div}, clone-element, create-class} = require \react

module.exports = create-class do 

    display-name: \Layout

    # get-default-props :: a -> Props
    get-default-props: ->
        cache: undefined # Boolean
        class-name: ""
        extras: {}
        parameters: {}
        prefix-styles: true
        style: {}
        url: undefined # String

    # render :: a -> ReactElement
    render: ->
        div do
            class-name: "layout #{@props.class-name}"
            style: (if @props.prefix-styles then prefixer.prefix @props.style else @props.style)

            # CHILDREN
            Children.map do 
                @props.children
                (child) ~> 

                    # STORY | LAYOUT
                    clone-element do 
                        child
                        cache: child.props?.cache ? @props.cache
                        extras: {} <<< @props.extras <<< child.props.extras
                        parameters: @props.parameters
                        url: child.props?.url ? @props.url

    