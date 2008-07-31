require File.dirname(__FILE__) + '/spec_helper'

describe "Maply" do
  
  before(:each) do
    ENV['RAILS_ENV'] = "test"
    YAML.stub!(:load_file).and_return(:test => {
                                        :google => "rewiuhndsfbdsfkbjhfsdn"})
    @map = Maply::Map.new
  end
  
  it "should wrap javascript in function" do
    @map.to_javascript.should be_include("function initializeMaplyMap() {")
  end
    
  it "should attach the onload event" do
    @map.to_javascript.should be_include("maplyAddEvent(window, 'load', initializeMaplyMap);")
  end
  
  it "should attach the unload event" do
    @map.to_javascript.should be_include("maplyAddEvent(window, 'unload', unloadMaplyMap);")
  end
  
  it "should support event listeners" do
    event1 = Maply::Event.new(:event => :moveend, :function => "alert('moved');")
    event2 = Maply::Event.new(:event => :click, :function => "alert('clicked);")
    @map.events << event1
    @map.events << event2
    @map.events.should be_include(event1)
    @map.events.should be_include(event2)
  end
    
  describe "when creating a google map" do
    it "should get the API key from the config file" do
      YAML.should_receive(:load_file).and_return(:test => {
                                                    :google => "rewiuhndsfbdsfkbjhfsdn"})
      Maply::Map.new(:api => :google)    
    end

    describe "and generating javascript" do
      it "should generate the unload code" do
        @map = Maply::Map.new(:api => :google)
        @map.to_javascript.should be_include("function unloadMaplyMap() {\n  GUnload();\n}")
      end
      
      it "should return the center point co-ordinates" do
        @map = Maply::Map.new(:api => :google,
                              :latitude=>'37.4419',
                              :longitude=>'-122.1419')
        @map.to_javascript.should be_include(%q{var map = new google.maps.Map2(document.getElementById("map"));})
        @map.to_javascript.should be_include(%q{map.setCenter(new google.maps.LatLng(37.4419, -122.1419), 0);})
      end

      it "should set the zoom level percentage" do
        @map = Maply::Map.new(:api => :google,
                              :zoom => '100')
        @map.to_javascript.should be_include(%q{var map = new google.maps.Map2(document.getElementById("map"));})
        @map.to_javascript.should be_include(%q{map.setCenter(new google.maps.LatLng(0, 0), 19);})
      end

      it "should include the required google dependencies" do
        @map = Maply::Map.new(:api => :google)
        @map.to_javascript.should be_include(%Q{<script type="text/javascript" src="http://www.google.com/jsapi?key=rewiuhndsfbdsfkbjhfsdn"></script>})
        @map.to_javascript.should be_include(%Q{google.load("maps", "2");})
      end
      
      it "should reference the named container" do
        @map = Maply::Map.new(:api => :google, :id => "my-map")
        @map.to_javascript.should be_include(%q{var my_map = new google.maps.Map2(document.getElementById("my-map"));})
      end

      it "should check the google maps compatibility" do
        @map = Maply::Map.new(:api => :google)
        @map.to_javascript.should be_include(%Q{if (GBrowserIsCompatible()) \{})
      end
    
      describe "and adding event listeners" do
        it "should output the javascript for the event listener" do
          @map = Maply::Map.new(:api => :google)
          event = Maply::Event.new(:event => :moveend, :function => "alert('moved');")
          @map.events << event
          @map.to_javascript.should be_include(%Q{GEvent.addListener(map, 'moveend', alert('moved');})
        end
        
      end

      describe "and setting display controls" do
        it "should remove undesired map types" do          
          @map = Maply::Map.new(:api => :google,
                                :type => {:except => [:hybrid, :satellite] })
          @map.to_javascript.should be_include(%Q{map.removeMapType(G_HYBRID_MAP);})
          @map.to_javascript.should be_include(%Q{map.removeMapType(G_SATELLITE_MAP);})
        end
        
        it "should keep desired map types" do          
          @map = Maply::Map.new(:api => :google,
                                :type => {:only => [:hybrid, :satellite] })
          @map.to_javascript.should be_include(%Q{map.removeMapType(G_PHYSICAL_MAP);})
          @map.to_javascript.should be_include(%Q{map.removeMapType(G_NORMAL_MAP);})          
        end
        
        it "should add large control" do
          @map = Maply::Map.new(:api => :google,
                                :controls => [:large])
          @map.to_javascript.should be_include(%Q{map.addControl(new GLargeMapControl());})
        end
        
        it "should add small control" do
          @map = Maply::Map.new(:api => :google,
                                :controls => [:small])
          @map.to_javascript.should be_include(%Q{map.addControl(new GSmallMapControl());})
        end
        
        it "should add overview and scale controls" do
          @map = Maply::Map.new(:api => :google,
                                :controls => [:overview, :scale])
          @map.to_javascript.should be_include(%Q{map.addControl(new GScaleControl());})
          @map.to_javascript.should be_include(%Q{map.addControl(new GOverviewMapControl());})
        end
      end
      
      describe "and adding markers" do
        before(:each) do 
          @map = Maply::Map.new(:api => :google)
        end
        
        it "should create the marker" do
          marker = Maply::Marker.new(:latitude => 32, :longitude => 52)
          @map.markers << marker
          @map.to_javascript.should be_include(%Q{ = new GMarker(GLatLng(32,52), {})})
        end
        
        it "should be draggable" do
          marker = Maply::Marker.new(:latitude => 32, :longitude => 52,
                                     :draggable => true)
          @map.markers << marker
          @map.to_javascript.should be_include(%Q{ = new GMarker(GLatLng(32,52), {draggable: true});})
        end
        
        it "should add the overlay for the marker" do
          marker = Maply::Marker.new(:name => "myMarker")
          @map.markers << marker
          @map.to_javascript.should be_include(%Q{map.addOverlay(myMarker);})
        end
        
        
      end

      describe "and adding icons" do
        before(:each) do 
          @map = Maply::Map.new(:api => :google)
        end
        
        it "should create the icon" do
          icon = Maply::Icon.new(:name => "myIcon")
          @map.icons << icon
          @map.to_javascript.should be_include(%Q{var myIcon = new GIcon();})
        end
                               
        it "should set the icon attributes" do
          icon = Maply::Icon.new(:name => "myIcon",
                                 :image => "/images/foo.png",
                                 :height => 10,
                                 :width => 20,
                                 :anchor_x => 5,
                                 :anchor_y => 7,
                                 :shadow_image => "/images/foo_shadow.png",
                                 :shadow_height => 12,
                                 :shadow_width => 30,
                                 :window_anchor_x => 8,
                                 :window_anchor_y => 9)
          @map.icons << icon
          javascript = @map.to_javascript
          javascript.should be_include(%Q{var myIcon = new GIcon();})
          javascript.should be_include(%Q{myIcon.image = "/images/foo.png";})
          javascript.should be_include(%Q{myIcon.shadow = "/images/foo_shadow.png";})
          javascript.should be_include(%Q{myIcon.iconSize = new GSize(20, 10);})
          javascript.should be_include(%Q{myIcon.shadowSize = new GSize(30, 12);})
          javascript.should be_include(%Q{myIcon.iconAnchor = new GPoint(5, 7);})
          javascript.should be_include(%Q{myIcon.infoWindowAnchor = new GPoint(8, 9);})
        end
        
        it "should be able to add an icon to a marker" do
          icon = Maply::Icon.new(:name => "myIcon")
          marker = Maply::Marker.new(:name => "myMarker", 
                                     :latitude => 32, 
                                     :longitude => 52,
                                     :icon => icon)
           @map.markers << marker
           javascript = @map.to_javascript
           javascript.should be_include(%Q{var myIcon = new GIcon();})
           javascript.should be_include(%Q{var myMarker = new GMarker(GLatLng(32,52), {icon: myIcon})})
        end
        
        it "should be able to reference an existing icon by name" do
          marker = Maply::Marker.new(:name => "myMarker", 
                                     :latitude => 32, 
                                     :longitude => 52,
                                     :icon => "myIcon")
           @map.markers << marker
           @map.to_javascript.should be_include(%Q{var myMarker = new GMarker(GLatLng(32,52), {icon: myIcon})})
        end
      end
    end
    
    describe "and generating HTML output" do
      it "should create a container div" do
        @map = Maply::Map.new
        @map.to_html.should be_include(%Q{<div id="map" style="width: 500px; height: 300px"></div>})
      end
      
      it "should use provided map name, height, and width" do
        @map = Maply::Map.new(:id => "my-map",
                              :width => "100%",
                              :height => "200px")
        @map.to_html.should be_include(%Q{<div id="my-map" style="width: 100%; height: 200px"></div>})
      end
    end
    
  end
end