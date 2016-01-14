{filter, fold, id, is-it-NaN, map, Obj, pairs-to-obj} = require \prelude-ls
{is-equal-to-object} = require \prelude-extension
{DOM:{div, input}, Children, clone-element, create-class, create-factory} = require \react
Form = create-factory require \./Form
require! \react-selectize
SimpleSelect = create-factory react-selectize.SimpleSelect

# float :: String -> Float?
float = (n) -> 
    result = parse-float n
    if is-it-NaN result then undefined else result

module.exports = create-class do

    display-name: \Storyboard

    # get-default-props :: a -> Props
    get-default-props: ->
        '''
        Control :: {
            name :: String, 
            type :: String, 
            label :: String,
            placeholder :: String, 
            options: [{label :: String, value :: a}], 
            default-value :: a, 
            ui-value-from-state :: State -> UIValue, 
            state-from-ui-value :: UIValue -> State, 
            parameters-from-ui-value :: UIValue -> Parameters, where Parameters :: Map Name, Value
            render? :: UIValue -> (UIValue -> Void) -> ReactElement
        }
        '''
        parameters: {}
        pipe-web-client-end-point: undefined # String
        controls: [] # [Control]
        state: {} # state :: State
        
        # on-change :: State -> Void
        on-change: (state) !-> 

    # render :: a -> ReactElement
    render: ->

        # update controls with defaults for the (ui-value-from-state, state-from-ui-value & parameters-from-ui-value) functions
        controls = @props.controls |> map ({
            name, type, ui-value-from-state, state-from-ui-value, parameters-from-ui-value
        }:control?) ~>

            # handle cases where the state value or the ui value may be a string for default html input controls
            # f :: StateValue -> UIValue
            f = match type
                | \number => float
                | \checkbox => (state-value) ->
                    if typeof state-value == \string
                        match state-value
                            | \true => true
                            | \false => false
                            | _ => undefined
                    else
                        state-value
                | _ => i

            {} <<< control <<<

                # ui-value-from-state :: State -> UIValue
                ui-value-from-state: ui-value-from-state ? (state) ~>  f state[name]
                    
                # state-from-ui-value :: UIValue -> State
                state-from-ui-value: state-from-ui-value ? (ui-value) ~> "#{name}" : f ui-value
                
                parameters-from-ui-value: parameters-from-ui-value ? (ui-value) ~> "#{name}" : ui-value
        
        # extract (parameters :: Map String, a) from controls
        parameters = controls 
            |> map ({name, default-value, ui-value-from-state, parameters-from-ui-value, client-side}?) ~> 
                (parameters-from-ui-value (ui-value-from-state @props.state) ? default-value) |> Obj.map ->
                    value: it
                    client-side: client-side
            |> fold do 
                (memo, obj) ~> {} <<< memo <<< obj
                {}

        div do 
            class-name: \storyboard

            # FORM
            Form do

                # InputField :: {
                #     name :: String,
                #     label :: String,
                #     default-value :: UIValue
                #     value :: UIValue
                #     render? :: UIValue -> (UIValue -> Void) -> ReactElement
                # }
                # input-fields :: [InputField]
                input-fields: controls |> map ({
                    name, label, type, default-value, placeholder, options, ui-value-from-state, render
                }?) ~>
                    {
                        name
                        label
                        type
                        default-value
                        value: ui-value-from-state @props.state
                        render: render ? (value, on-change) ->
                            switch type
                            | \select =>
                                SimpleSelect do 
                                    placeholder: placeholder
                                    value: 
                                        | typeof value == \undefined => undefined
                                        | _ => 
                                            label: value
                                            value: value
                                    options: options
                                    on-value-change: ({value}, callback) ~> 
                                        on-change value
                                        callback!

                            | _ =>
                                input {
                                    type
                                    placeholder
                                    on-change: ({current-target}) ~>

                                        # f :: DOMElement -> UIValue
                                        f = match type
                                            | \checkbox => (.checked)
                                            | _ => (.value)

                                        on-change f current-target
                                } <<< (if type == \checkbox then {checked: value} else {value})
                    }

                # this method converts a set of ui-values to state and calls the parent component
                # on-submit :: FormData -> Void, where FormData :: Map InputFieldName, InputFiedValue
                on-submit: (form-data) !~>
                    @props.on-change do 
                        controls
                            |> map ({name, state-from-ui-value}) ~> state-from-ui-value form-data[name]
                            |> fold do 
                                (memo, value) -> {} <<< memo <<< value 
                                {}

            div do 
                class-name: \stories

                # pass parameters to all the children (stories)
                Children.map do 
                    @props.children
                    (child) ~>

                        # STORY | LAYOUT | STORYBOARD
                        clone-element do 
                            child
                            parameters: {} <<< @props.parameters <<< parameters 
                            pipe-web-client-end-point: child.props?.pipe-web-client-end-point ? @props.pipe-web-client-end-point
