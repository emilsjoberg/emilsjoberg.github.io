
class BubbleChart
  constructor: (data) ->
    @data = data
    @width = 940
    @height = 600

    @tooltip = CustomTooltip("sentiment_tooltip", 240)

    # locations the nodes will move towards
    # depending on which view is currently being
    # used
    @center = {x: @width / 2, y: @height / 2}
    @sentiment_centers = {
      "positive": {x: @width / 3, y: @height / 2},
      "neutral": {x: @width / 2, y: @height / 2},
      "negative": {x: 2 * @width / 3, y: @height / 2}
    }
    @type_centers = {
      "video": {x: @width / 3, y: @height / 2},
      "tweet": {x: @width / 2, y: @height / 2},
      "blog": {x: 2 * @width / 3, y: @height / 2}
    }

    # used when setting up force and
    # moving around nodes
    @layout_gravity = -0.01
    @damper = 0.1

    # these will be set in create_nodes and create_vis
    @vis = null
    @nodes = []
    @force = null
    @circles = null

    # colors based on sentiment
    @fill_color = d3.scale.ordinal()
      .domain(["negative", "neutral", "positive"])
      .range(["#d84b2a", "#d9d9d9", "#7aa25c"])

    # use the max total_amount in the data as the max in the scale's domain
    max_amount = d3.max(@data, (d) -> d.total_amount)
    @radius_scale = d3.scale.pow().exponent(0.5).domain([0, max_amount]).range([2, 14])
    
    this.create_nodes()
    this.create_vis()

  # create node objects from original data
  # that will serve as the data behind each
  # bubble in the vis, then add each node
  # to @nodes to be used later
  create_nodes: () =>
    @data.forEach (d) =>
      node = {
        id: d.id
        radius: @radius_scale(parseInt(d.total_amount))
        value: d.total_amount
        name: d.keyword
        #org: d.organization
        group: d.sentiment
        position: d.sentiment
        x: Math.random() * 900
        y: Math.random() * 800
        type: d.type
      }
      @nodes.push node

    @nodes.sort (a,b) -> b.value - a.value


  # create svg at #vis and then 
  # create circle representation for each node
  create_vis: () =>
    @vis = d3.select("#vis").append("svg")
      .attr("width", @width)
      .attr("height", @height)
      .attr("id", "svg_vis")

    @circles = @vis.selectAll("circle")
      .data(@nodes, (d) -> d.id)

    # used because we need 'this' in the 
    # mouse callbacks
    that = this

    # radius will be set to 0 initially.
    # see transition below
    @circles.enter().append("circle")
      .attr("r", 0)
      .attr("fill", (d) => @fill_color(d.group))
      .attr("stroke-width", 2)
      .attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
      .attr("id", (d) -> "bubble_#{d.id}")
      .on("mouseover", (d,i) -> that.show_details(d,i,this))
      .on("mouseout", (d,i) -> that.hide_details(d,i,this))

    # Fancy transition to make bubbles appear, ending with the
    # correct radius
    @circles.transition().duration(2000).attr("r", (d) -> d.radius)


  # Charge function that is called for each node.
  # Charge is proportional to the diameter of the
  # circle (which is stored in the radius attribute
  # of the circle's associated data.
  # This is done to allow for accurate collision 
  # detection with nodes of different sizes.
  # Charge is negative because we want nodes to 
  # repel.
  # Dividing by 8 scales down the charge to be
  # appropriate for the visualization dimensions.
  charge: (d) ->
    -Math.pow(d.radius, 2.0) / 8

  # Starts up the force layout with
  # the default values
  start: () =>
    @force = d3.layout.force()
      .nodes(@nodes)
      .size([@width, @height])

  # Sets up force layout to display
  # all nodes in one circle.
  display_group_all: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_center(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_sentiment() #HIDE_YEARS
    this.hide_type() #HIDE TYPES

  # Moves all circles towards the @center
  # of the visualization
  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
      d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha

  # sets the display of bubbles to be separated
  # into each year. Does this by calling move_towards_year
  display_by_sentiment: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_sentiment(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.display_sentiment()

  # move all circles to their associated @sentiment_centers 
  move_towards_sentiment: (alpha) =>
    (d) =>
      target = @sentiment_centers[d.group]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1

  # Method to display year titles
  display_sentiment: () =>
    sentiment_x = {"positive": 160, "neutral": @width / 2, "negative": @width - 160}
    sentiment_data = d3.keys(sentiment_x)
    sentiment = @vis.selectAll(".sentiment")
      .data(sentiment_data)

    sentiment.enter().append("text")
      .attr("class", "sentiment")
      .attr("x", (d) => sentiment_x[d] )
      .attr("y", 40)
      .attr("text-anchor", "middle")
      .text((d) -> d)

  # Method to hide year titles
  hide_sentiment: () => #changed
    sentiment = @vis.selectAll(".sentiment").remove()


    ############ INTRODUCING TYPE

# sets the display of bubbles to be separated
  # into each type. Does this by calling move_towards_type
  display_by_type: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_type(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.display_type()

  # move all circles to their associated @sentiment_centers 
  move_towards_type: (alpha) =>
    (d) =>
      target = @type_centers[d.group]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1

  # Method to display year titles
  display_type: () =>
    type_x = {"video": 160, "tweet": @width / 2, "blog": @width - 160}
    type_data = d3.keys(type_x)
    type = @vis.selectAll(".type")
      .data(type_data)

    type.enter().append("text")
      .attr("class", "type")
      .attr("x", (d) => type_x[d] )
      .attr("y", 40)
      .attr("text-anchor", "middle")
      .text((d) -> d)

  # Method to hide type
  hide_type: () => #changed
    sentiment = @vis.selectAll(".type").remove()


    ################ END OF TYPE

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "black")
    content = "<span class=\"name\">Keyword:</span><span class=\"value\"> #{data.name}</span><br/>"
    content +="<span class=\"name\">Frequency:</span><span class=\"value\"> #{addCommas(data.value)}</span><br/>"
    content +="<span class=\"name\">Sentiment:</span><span class=\"value\"> #{data.group}</span>"
    content +="<span class=\"name\">Type:</span><span class=\"value\"> #{data.type}</span>"
    @tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
    @tooltip.hideTooltip()


root = exports ? this

$ ->
  chart = null

  render_vis = (csv) ->
    chart = new BubbleChart csv
    chart.start()
    root.display_all()
  root.display_all = () =>
    chart.display_group_all()
  root.display_sentiment = () =>
    chart.display_by_sentiment()
    #added
  root.display_type = () =>
    chart.display_by_type()
  root.toggle_view = (view_type) =>
    if view_type == 'sentiment'
      root.display_sentiment()
    else 
      if view_type == "type" =>
        root.display_type()
      else
        root.display_all()

  d3.csv "data/all_tweets_topictype.csv", render_vis
