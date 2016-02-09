require! \moment
{map} = require \prelude-ls
{{a, div}:DOM, create-class, create-factory} = require \react
{render} = require \react-dom
require! \react-router
{hash-history} = react-router
Link = create-factory react-router.Link 
Route = create-factory react-router.Route
Router = create-factory react-router.Router
pipe-storyboard = require \../../src/index
Layout = create-factory pipe-storyboard.Layout
Story = create-factory pipe-storyboard.Story
Storyboard = create-factory pipe-storyboard.Storyboard
{update-querystring} = require \./utils.ls
DateRange = create-factory require \./DateRange.ls

App = create-class do 

  display-name: \App

  # render :: a -> ReactElement
  render: ->
    default-from-date = moment!.subtract 3, \month .format \YYYY-MM-DDTHH:mm
    from-date = @props.location.query?.from ? default-from-date

    default-to-date = moment!.format \YYYY-MM-DDTHH:mm
    to-date = @props.location.query?.to ? default-to-date
    
    Storyboard do 
      url: \http://rf.pipend.com
      controls: 
        * name: \Range
          default-value: 
            ago: '1 month'
            from-date: default-from-date
            to-date: default-to-date
          ui-value-from-state: ({ago, from, to}) -> {ago, from, to}
          state-from-ui-value: ({ago, from, to}) -> {ago, from, to}
          parameters-from-ui-value: ({ago, from, to}) ->
            if ago == \custom then {ago: "", from, to} else {from: null, to: null, ago}
          render: (value, on-change) ~>
            DateRange do 
              {} <<< value <<< on-change: (patch) ~> 
                on-change {} <<< value <<< patch

        * name: \searchString
          label: \search
          type: \text
          default-value: ""

        * name: \username
          label: \username
          type: \text
          default-value: ""

        * name: \channel
          label: \channel
          type: \select
          placeholder: 'Select channels'
          options: @state.channels
          multi: true

        * name: \limit
          label: \limit
          type: \number
          default-value: 100
        ...
      state: @props.location.query

      # on-change :: StoryboardState -> ()
      on-change: (new-state) ~> 
        hash-history.replace (update-querystring window.location.href, new-state)

      Layout do 
        style:
          display: \flex
          flex-direction: \column

        # SEARCH
        Story do 
          style:
            height: \70%
          branch-id: \pBoHVpe
          render-links: ({branch-id, query-id, url}) ~>
            segment = if branch-id then "branches/#{branch-id}" else "query/#{query-id}"
            div class-name: \links,
              a href: "#{url}/#{segment}", 'View Query'

        # TREND
        Layout do 
          extras:
            bucket-size: 86400000
            limit: 10
            show-legend: true
          style: 
            display: \flex
            flex-direction: \column

          # PER CHANNEL
          Story do 
            extras:
              fieldname: \channelName
            title: "Channel popularity (in terms of # of messages) over time"
            style:
              border-right: '1px solid #ccc'
              flex: 1
              height: 500
            branch-id: \prKRkKP
          
          # PER USER
          Story do 
            extras:
              fieldname: \username
            title: "Top contributers (in terms of # of messages) over time"
            style:
              flex: 1
              height: 500
            branch-id: \prKRkKP

  get-initial-state: ->
    channels: []

  # component-will-mount :: () -> ()
  component-will-mount: !->
    fetch "http://rf.pipend.com/apis/branches/pBtfJqR/execute/86400/transformation"
      .then (.json!)
      .then ~> @set-state channels: it

render do 
  Router do 
    history: hash-history
    Route path: \/, component: App
  document.get-element-by-id \mount-node