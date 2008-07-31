require 'yaml'

module Maply
  class Map
    
    attr_accessor :name, :events, :markers, :icons
    
    MAP_TYPES = { :hybrid => "G_HYBRID_MAP",
                  :satellite => "G_SATELLITE_MAP",
                  :normal => "G_NORMAL_MAP",
                  :physical => "G_PHYSICAL_MAP"}
                  
    MAP_CONTROLS = { :large => "GLargeMapControl",
                     :small => "GSmallMapControl",
                     :zoom => "GSmallZoomControl",
                     :scale => "GScaleControl",
                     :type => "GMapTypeControl",
                     :nested_type => "GHierarchicalMapTypeControl",
                     :overview => "GOverviewMapControl"}
    
    @@loaded_dependencies = false
    
    def initialize(options = {})
      @options = {
        :api => :google,
        :id => "map",
        :width => "500px",
        :height => "300px",
        :latitude => 0,
        :longitude => 0,
        :zoom => 0,
        :type => :all,
        :controls => [:small, :scale, :type, :overview]
      }
      @options.merge!(options)
      @options[:zoom] = 19*(options[:zoom].to_i/100) if options[:zoom]
      config = YAML.load_file("#{RAILS_ROOT}/config/maply.yml")          
      @options[:api_key] = config[ENV['RAILS_ENV'].to_sym][@options[:api]]
      @name = variablize(@options[:id])
      
      @events = []
      @markers = []
      @icons = []
      
      self
    end
    
    def <<(value)
      super
    end
    
    def to_javascript
      @markers.each do |marker|
        @icons << marker.icon if marker.icon.is_a?(Maply::Icon)
      end
      
      javascript = ""
      unless @@loaded_dependencies
        javascript << <<-EOF
<script type="text/javascript" src="http://www.google.com/jsapi?key=#{@options[:api_key]}"></script>
<script type="text/javascript">
//<![CDATA[
google.load("maps", "2");
//]]>
</script>
EOF
      end
      
      javascript << <<-EOF
function initializeMaply#{@name.capitalize}() {
  if (GBrowserIsCompatible()) {
    var #{@name} = new google.maps.Map2(document.getElementById("#{@options[:id]}"));
    #{@name}.setCenter(new google.maps.LatLng(#{@options[:latitude]}, #{@options[:longitude]}), #{@options[:zoom]});
    #{output_event_listeners}
    #{output_map_types}
    #{output_controls}
    #{output_icons}
    #{output_markers}
    #{output_overlays}
  }
}
function unloadMaply#{@name.capitalize}() {
  GUnload();
}

maplyAddEvent(window, 'load', initializeMaply#{@name.capitalize});
maplyAddEvent(window, 'unload', unloadMaply#{@name.capitalize});
//]]>
</script>
EOF
      # unless @@loaded_dependencies
      #   javascript << %Q{<script type="text/javascript" src="http://www.google.com/jsapi?key=#{@options[:api_key]}"></script>}
      # end
    end
    
    def to_html
      html = <<-EOF
<div id="#{@options[:id]}" style="width: #{@options[:width]}; height: #{@options[:height]}"></div>
EOF
    end
    
    private
      def variablize(string)
        string.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
      end
      
      def output_event_listeners
        @events.map do |event|
          "\tGEvent.addListener(#{@name}, '#{event.event}', #{event.function});"
        end.join("\n")
      end
      
      def output_map_types
        output = []
        if @options[:type].is_a?(Symbol)
          case @options[:type]
          when :all
            return
          end
        elsif @options[:type].is_a?(Hash)
          case @options[:type].keys.first
          when :except
            output =  @options[:type][:except].map do |type|
              "\tmap.removeMapType(#{MAP_TYPES[type]});"              
            end
          when :only
            output =  MAP_TYPES.reject{|k,v| @options[:type][:only].include?(k)}.map do |key, type|
              "\tmap.removeMapType(#{type});"
            end
          end

        end
        return output.join("\n")
      end
      
      def output_controls
        output = []
        @options[:controls].each do |control|
          output << "\tmap.addControl(new #{MAP_CONTROLS[control]}());"
        end
        output.join("\n")
      end
      
      def output_markers
        output = []
        @markers.each do |marker|
          this_options = []
          this_marker = []
          this_options << "draggable: true" if marker.draggable
          this_options << "icon: #{marker.icon.name}" if marker.icon.is_a?(Maply::Icon)
          this_options << "icon: #{marker.icon}" if marker.icon.is_a?(String)
          this_marker << "var #{marker.name} = new GMarker(GLatLng(#{marker.latitude},#{marker.longitude}), {"
          this_marker << this_options.join(", ")
          this_marker << "});"
          output << this_marker.join
        end
        output.join("\n")
      end
      
      def output_overlays
        output = []
        @markers.each do |marker|
          output << "\tmap.addOverlay(#{marker.name});"
        end
        output.join("\n")
      end
      
      def output_icons
        output = []
        @icons.each do |icon|
          output << "var #{icon.name} = new GIcon();"
          output << %Q{#{icon.name}.image = "#{icon.image}";} if icon.image
          output << %Q{#{icon.name}.shadow = "#{icon.shadow_image}";} if icon.shadow_image          
          output << "#{icon.name}.iconSize = new GSize(#{icon.width}, #{icon.height});" if icon.width && icon.height
          output << "#{icon.name}.shadowSize = new GSize(#{icon.shadow_width}, #{icon.shadow_height});" if icon.shadow_width && icon.shadow_height
          output << "#{icon.name}.iconAnchor = new GPoint(#{icon.anchor_x}, #{icon.anchor_y});" if icon.anchor_x && icon.anchor_y
          output << "#{icon.name}.infoWindowAnchor = new GPoint(#{icon.window_anchor_x}, #{icon.window_anchor_y});" if icon.window_anchor_x && icon.window_anchor_y
        end
        output.join("\n")        
      end
      
  end
end