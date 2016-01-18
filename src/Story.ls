require! \clipboard
{is-equal-to-object} = require \prelude-extension
require! \pipe-web-client
{all, filter, id, map, Obj, obj-to-pairs, pairs-to-obj} = require \prelude-ls
require! \querystring
{DOM:{a, div}, create-class, create-factory} = require \react
{find-DOM-node} = require \react-dom

module.exports = create-class do 

    display-name: \Story

    # get-default-props :: a -> Props
    get-default-props: ->
        branch-id: "" 
        cache: undefined # Boolean
        class-name: ""
        parameters: {} # Map ParameterName, {value :: a, client-side :: Boolean}
        query-id: ""
        show-links: true
        show-title: true
        style: {}
        title: undefined
        url: undefined # String

    # render :: a -> ReactElement
    render: ->
        {url, show-title, show-links} = @props
        parameters = @props.parameters |> Obj.map (.value)
        share-url = "#{url}/apis/branches/#{@props.branch-id}/execute/true/presentation?"
        expand = !show-title and !show-links

        div do 
            class-name: "story #{@props.class-name} #{if @state.loading then 'loading' else ''} #{if expand then 'expand' else ''}"
            style: @props.style

            if !expand
                div do 
                    class-name: \header

                    # TITLE
                    if @props.show-title
                        div do 
                            class-name: \title
                            @props.title ? @state.document.query-title

                    # BUTTONS
                    if @props.show-links
                        div do 
                            class-name: \buttons

                            a do 
                                href: "#{url}/branches/#{@props.branch-id}"
                                target: \_blank
                                \Edit

                            a do
                                href: "#{share-url}#{decode-URI-component querystring.stringify parameters}"
                                target: \_blank
                                \Share

                            a do 
                                ref: \parameters
                                \data-clipboard-text : (JSON.stringify parameters, null, 4)
                                \Parameters
                                
                            a do 
                                href: "#{url}/ops"
                                target: \_blank
                                'Task Manager'

            # PRESENTATION
            div do 
                class-name: \presentation-container
                ref: \presentation-container

    # get-initial-state :: a -> UIState
    get-initial-state: ->
        loading: false
        document : {} # {query-title :: String, ...}
        # execute :: Parameters -> Boolean -> p result
        # presentation-function :: Parameters -> DOMElement -> result
        # result :: object

    # component-will-mount :: () -> Void        
    component-will-mount: !->
        {compile-latest-query} = pipe-web-client end-point: @props.url

        # load & compile the query from pipe
        {document, execute, transformation-function, presentation-function} <~ compile-latest-query @props.branch-id .then _

        # update the state with:
        #  execute :: Parameters -> p result
        #  tranformation-function :: result -> Parameters -> result
        #  presentation-function :: DOMElement -> result -> Parameters -> DOM()
        <~ @set-state {document, execute, transformation-function, presentation-function, loading: true}

        parameters = @props.parameters |> Obj.map (.value)

        # use parameters to execute the query and update the state with the result
        result <~ @state.execute @props.cache, parameters .then _
        <~ @set-state {result, loading: false}
        
        # present the result
        presentation-function do 
            find-DOM-node @refs[\presentation-container]
            transformation-function result, parameters
            parameters

    # component-did-mount :: () -> Void
    component-did-mount: !->
        if !!@refs.parameters
            new clipboard find-DOM-node @refs.parameters

    # component-will-receive-props :: Props -> Void
    component-will-receive-props: (next-props) !->
        
        {execute, transformation-function, presentation-function}? = @state

        if !!execute

            # change :: [[name, {value, client-side}]]
            change = next-props.parameters
                |> obj-to-pairs
                |> filter ~> !(it.1?.value `is-equal-to-object` @props.parameters?[it.0]?.value)
                
            if change.length > 0
                client-side = change |> all -> !!it.1?.client-side
                parameters = next-props.parameters |> Obj.map (.value)
                view = find-DOM-node @refs[\presentation-container]

                if client-side
                    presentation-function do 
                        view
                        transformation-function @state.result, parameters
                        parameters

                else
                    <~ @set-state loading: true
                    result <~ execute @props.cache, parameters .then _
                    <~ @set-state {result, loading: false}
                    presentation-function do 
                        view
                        transformation-function result, parameters
                        parameters

