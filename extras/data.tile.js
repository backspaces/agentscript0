// TileDataSet is a [DataSet](data.html) implementation for modeling
// with data in image tiles. It binds to [Leaflet](http://leafletjs.com) to make it
// easier to get data out of a tile server and into a model.

// TODO:
// * Rather than accessing data directly from tiles, it
//   would make more sense to access data from a data[] array
//   that we keep up to date as tile data is loaded. This would make
//   it easy to support other DataSet functions, like convolve()
//   and slopeAndAspect()
// * Gracefully handle the min and max zoom options of L.tileLayer

(function() {
    ABM.TileDataSet = (function() {

        function TileDataSet(width, height, tileSize) {
        	this.tileSize = tileSize || 256;

        	this.tiles = {};

        	this.width = width;
        	this.height = height;

        	this.zoom = 0;
        	this.origin = { x: 0, y: 0 };
        }

        TileDataSet.prototype = new ABM.DataSet();

        TileDataSet.prototype.getXY = function(x, y) {
        	this.checkXY(x, y);

        	var tileCtx = this.getTileContainingPoint(x, y);
        	
        	var pixelCoord = {
        		x: this.origin.x + x,
        		y: this.origin.y + y
        	};

        	var xOffset = pixelCoord.x % this.tileSize,
        		yOffset = pixelCoord.y % this.tileSize;

        	var imageData = tileCtx.getImageData(xOffset, yOffset, 1, 1).data;
        	var res = this.parseTileData(imageData);
        	return res;
        }

        TileDataSet.prototype.bilinear = function(x, y) {
        	this.checkXY(x, y);

        	var x0 = Math.floor(x),
        		y0 = Math.floor(y),
        		x = x - x0,
        		y = y - y0,
        		dx = 1 - x,
        		dy = 1 - y;

        	var f00 = this.getXY(x0, y0),
        		f01 = this.getXY(x0, y0+1),
        		f10 = this.getXY(x0+1, y0),
        		f11 = this.getXY(x0+1, y0+1);

        	return f00*dx*dy + f10*x*dy + f01*dx*y + f11*x*y;
        }

        TileDataSet.prototype.addTile = function(tilePoint, tile) {
        	var tileId = [tilePoint.z, tilePoint.x, tilePoint.y].join("/");
        	this.tiles[tileId] = tile;
        }

        TileDataSet.prototype.getTileContainingPoint = function(x, y) {
        	var zoom = this.zoom,
        		pixelCoord = {
        			x: this.origin.x + x,
        			y: this.origin.y + y
        		};

        	var tileX = Math.floor(pixelCoord.x / this.tileSize),
        		tileY = Math.floor(pixelCoord.y / this.tileSize);

        	var tileCtx = this.tiles[zoom+"/"+tileX+"/"+tileY];
        	
        	if (!tileCtx) {
        		console.log("ERR: tried to sample tile", zoom, tileX, tileY, "but it doesn't exist.");
        	}

        	return tileCtx;
        }

        // Depending on how your data is
        // encoded in your tiles, you may
        // want to implement a custom parser

        // The imageData paramater is image pixel data
        // returned by ctx.getImageData()
        TileDataSet.prototype.parseTileData = function(imageData) {
        	return imageData;
        }

        // Use Leaflet to dynamically load tiles into your dataset;
        // you should call this after initializing your model. Note
        // the tile layer must be an instance of L.CrossOriginTileLayer
        // (defined below) in order to get access to the imagedata.
        TileDataSet.prototype.bindToLeaflet = function(leafletMap, leafletLayer, preventMapEmbed) {
        	this.leafletMap = leafletMap;
        	this.leafletLayer = leafletLayer;

        	// by default, put the Leaflet div
        	// inside of the Agentscript wrapper
        	if (!preventMapEmbed) {
        		this.embedLeaflet();
        		var mapSize = this.leafletMap.getSize();
        		this.width = mapSize.x;
        		this.height = mapSize.y;
        	}

        	this.tileSize = this.tileSize || leafletLayer._getTileSize();
        	this.origin = this.leafletMap.getPixelBounds().min;
        	this.zoom = leafletMap.getZoom();

        	// Keep track of tiles as they are loaded
        	leafletLayer.on('tileload', function(e) {
        		var tilePoint = urlToTileCoords(e.url);

                if (!tilePoint) {
                    console.log("err: couldn't parse tile coordinates for", e.url);
                    return;
                }
        		
                var tile = ABM.util.imageToCtx(e.tile, this.tileSize, this.tileSize);
        		this.addTile(tilePoint, tile);
        	}.bind(this));

        	// Clear tile storage on zoom
        	leafletMap.on('zoomstart', function() {
        		this.tiles = {};
        	}.bind(this));

        	// Keep map top-left corner up to date
        	leafletMap.on('moveend', function() {
        		this.origin = this.leafletMap.getPixelBounds().min;
        	}.bind(this));

        	// Keep zoom up to date
        	leafletMap.on('zoomend', function() {
        		this.zoom = this.leafletMap.getZoom();
        	}.bind(this));

        	// Provide a way to listen for 'tilesready' events
        	// by wrapping the leafletLayer's event listener
        	this.on = function(name, fn) {
        		var leafletLayer = this.leafletLayer;
        		
        		if (!leafletLayer) {
        			return;
        		}

        		leafletLayer.on(name, fn);
        	}

        	// Fire 'tilesready' events only when the map
        	// is finished moving and the current tiles are
        	// finished loading
        	var mapReady = true,
        		tilesReady = false;

        	leafletLayer.on('loading', function() {
        		tilesReady = false;
        	});

        	leafletMap.on('movestart', function() {
        		mapReady = false;
        	});

        	leafletLayer.on('load', function() {
        		tilesReady = true;
        		if (mapReady) {
        			this.leafletLayer.fire('tilesready');
        		}
        	}.bind(this));

        	leafletMap.on('moveend', function() {
        		mapReady = true;
        		if (tilesReady) {
        			this.leafletLayer.fire('tilesready');
        		}
        	}.bind(this));

        	function urlToTileCoords(url) {
        		var coordRegex = /.*\/(\d+)\/(\d+)\/(\d+)\.png$/;
        		var coords = coordRegex.exec(url);
        		return coords && {
        			z: coords[1],
        			x: coords[2],
        			y: coords[3]
        		};
        	}
        }

        TileDataSet.prototype.embedLeaflet = function() {
        	if (!ABM.model.div) {
        		console.log("ERR: Tried to embed leaflet map into a headless model, or before model div was initialized.");
        		return;
        	}

        	ABM.util.insertLayer(ABM.model.div, this.leafletMap.getContainer(), ABM.world.pxWidth+"px", ABM.world.pxHeight+"px", 15);
            // Alert Leaflet that its dimensions have changed
            this.leafletMap.invalidateSize();
        }

        return TileDataSet;

    })();

}).call(this);

// # L.CrossOriginTileLayer
L.CrossOriginTileLayer = L.TileLayer.extend({
	_createTile: function () {
		var tile = L.TileLayer.prototype._createTile.apply(this);
        // Setting the crossOrigin attribute of the tiles
        // lets us access their imagedata
		tile.crossOrigin = '';
		return tile;
	}
});

L.crossOriginTileLayer = function (url, options) {
	return new L.CrossOriginTileLayer(url, options);
}