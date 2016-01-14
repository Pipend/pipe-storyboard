{all, any, filter, id, map, pairs-to-obj} = require \prelude-ls
{is-equal-to-object} = require \prelude-extension
{DOM:{div, input, label}, create-class, create-factory} = require \react

# parse-string :: a -> b
# parse-string :: if a is not a string then (a -> a)
# parse-string :: if a is a string then (String -> b)
parse-string = (value) ->
    parser = 
        | (/^\d+$/g.test value) => parse-int
        | (/^(\d|\.)+$/g.test value) => parse-float
        | value == \true => -> true
        | value == \false => -> false
        | value == '' => -> undefined
        | _ => id
    parser value

module.exports = create-class do 

    display-name: \Form

    # get-default-props :: a -> Props
    get-default-props: ->
        '''
        InputField :: {
            name :: String,
            label :: String,
            default-value :: a
            value :: a
            render? :: value -> (value -> Void) -> ReactElement
        }
        '''
        input-fields: [] # [InputField]

        # on-submit :: FormData -> Void
        on-submit: (form-data) !->

        # on-reset :: a -> Void
        on-reset: !->

    # render :: a -> ReactElement
    render: ->

        change = @props.input-fields 
            |> any ({name, default-value, value}) ~> 
                new-value = @state[name]
                old-value = value ? default-value

                # the parse-string function returns the same object if its not a string
                # the reasoning behind use of parse-string:
                #  the old-value comes from props and this value might be parsed value
                #  the new-value comes from the ui control's change listener 
                #  in the case of html input controls this will most likely be a string 
                #  even if the type of the control is 'number', which breaks the equality check
                #  so to level the plain field we call parse-string on lhs and rhs
                !((parse-string new-value) `is-equal-to-object` (parse-string old-value))

        div do 
            class-name: \form, 

            @props.input-fields |> map ({name, render}:input-field?) ~>
                value = @state[name]

                # ROW
                div do 
                    key: name

                    # LABEL
                    if !!input-field?.label
                        label null, input-field.label

                    # INPUT FIELD
                    render value, (new-value) ~> @set-state "#{name}" : new-value
                    
            div do
                class-name: \buttons

                # RESET BUTTON
                div do 
                    class-name: \button
                    on-click: ~> 
                        <~ @set-state do 
                            @props.input-fields
                                |> map ({name, default-value, value}?) -> [name, default-value]
                                |> pairs-to-obj
                        @props.on-reset!
                    \Reset

                # SEARCH BUTTON
                div do 
                    class-name: "button#{if change then ' highlight' else ''}"
                    on-click: ~>
                        @props.on-submit do 
                            @props.input-fields
                                |> map ({name}) ~> [name, @state[name]]
                                |> pairs-to-obj
                    \Search

    # get-initial-state :: a -> UIState
    get-initial-state: ->
        @props.input-fields
            |> map ({name, default-value, value}?) -> [name, value ? default-value]
            |> pairs-to-obj
