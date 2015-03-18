// TileDataSet is a [DataSet](data.html) implementation for modeling
// with data in image tiles. It binds to [Leaflet](http://leafletjs.com) to make it
// easier to get data out of a tile server and into a model.

// TODO:
// * Gracefully handle the min and max zoom options of L.tileLayer

(function() {
    ABM.TileDataSet = (function() {

        function TileDataSet(width, height, tileSize, model) {
            this.tileSize = tileSize || 256;

            this.tiles = {};

            this.width = width;
            this.height = height;

            this.model = model;

            this.zoom = 0;
            this.origin = { x: 0, y: 0 };
        }

        TileDataSet.prototype = new ABM.DataSet();

        TileDataSet.prototype.addTile = function(tilePoint, tile) {
            var tileId = [tilePoint.z, tilePoint.x, tilePoint.y].join("/");
            this.tiles[tileId] = tile;
        }

        // Get the tile containing a point (x,y) specified
        // in pixels relative to the dataset origin.
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

        // Copy data from all tiles into the data[] array.
        // You would typically call this once after adding all data tiles,
        // or after receiving a 'tilesready' event.
        TileDataSet.prototype.importTileData = function() {
            this.data = new Array(this.width*this.height);

            // initialize data with zeros
            for (var i = 0; i < this.data.length; i++) {
                this.data[i] = 0;
            }

            var mapTopLeft = this.origin, // in pixels
                mapBottomRight = {
                    x: mapTopLeft.x + this.width,
                    y: mapTopLeft.y + this.height
                },
                mapTopLeftTile = { // in tiles
                    x: Math.floor(mapTopLeft.x / this.tileSize),
                    y: Math.floor(mapTopLeft.y / this.tileSize)
                };

            var borderTileOffsets = {
                left: mapTopLeft.x % this.tileSize,
                top: mapTopLeft.y % this.tileSize,
                right: mapBottomRight.x % this.tileSize,
                bottom: mapBottomRight.y % this.tileSize
            };

            var tilesWide = Math.floor(this.width / this.tileSize),
                tilesHigh = Math.floor(this.height / this.tileSize);

            // iterate through visible tiles
            for (var tileX = 0; tileX <= tilesWide; tileX++) {
                for (var tileY = 0; tileY <= tilesHigh; tileY++) {
                    var curTile = this.getTileContainingPoint(tileX*this.tileSize, tileY*this.tileSize);

                    if (!curTile) {
                        continue;
                    }

                    var imageData = curTile.getImageData(0,0,this.tileSize,this.tileSize);

                    var curTilePos = { // in pixels
                        left: (mapTopLeftTile.x + tileX) * this.tileSize,
                        top: (mapTopLeftTile.y + tileY) * this.tileSize
                    };

                    var tileStartCoord = { x: 0, y: 0 };
                    var tileEndCoord = { x: this.tileSize-1, y: this.tileSize-1 };
                    if (tileX == 0)
                        tileStartCoord.x = borderTileOffsets.left;
                    if ((tileX + 1)*this.tileSize > this.width)
                        tileEndCoord.x = borderTileOffsets.right;
                    if (tileY == 0)
                        tileStartCoord.y = borderTileOffsets.top;
                    if ((tileY + 1)*this.tileSize > this.height)
                        tileEndCoord.y = borderTileOffsets.bottom;

                    // iterate through visible tile pixels
                    for (var x = tileStartCoord.x; x <= tileEndCoord.x; x++) {
                        for (var y = tileStartCoord.y; y <= tileEndCoord.y; y++) {
                            var dataCoord = {
                                x: x + curTilePos.left - mapTopLeft.x,
                                y: y + curTilePos.top - mapTopLeft.y
                            };
                            var idx = this.toIndex(dataCoord.x, dataCoord.y),
                                imageIdx = 4*(y*this.tileSize+x);

                            this.data[idx] = this.parseTileData([
                                imageData.data[imageIdx],
                                imageData.data[imageIdx+1],
                                imageData.data[imageIdx+2],
                                imageData.data[imageIdx+3]
                            ]);
                        }
                    }

                }
            }
        }

        // Depending on how your data is
        // encoded in your tiles, you may
        // want to implement a custom parser

        // The imageData paramater is of the form [r, g, b, a]
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

            this.tileSize = leafletLayer._getTileSize();
            this.origin = this.leafletMap.getPixelBounds().min;
            this.zoom = leafletMap.getZoom();

            // Keep track of tiles as they are loaded
            leafletLayer.on('tileload', function(e) {
                var tilePoint = urlToTileCoords(e.url);

                if (!tilePoint) {
                    console.log("err: couldn't parse tile coordinates for", e.url);
                    return;
                }

                var tile = ABM.Util.imageToCtx(e.tile, this.tileSize, this.tileSize);

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

            this.once = function(name, fn) {
                var leafletLayer = this.leafletLayer;
                
                if (!leafletLayer) {
                    return;
                }

                leafletLayer.once(name, fn);
            }

            this.off = function(name, fn) {
                var leafletLayer = this.leafletLayer;

                if (!leafletLayer) {
                    return;
                }

                leafletLayer.off(name, fn);
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
            if (!this.model.div) {
                console.log("ERR: Tried to embed leaflet map into a headless model, or before model div was initialized.");
                return;
            }

            ABM.Util.insertLayer(this.model.div, this.leafletMap.getContainer(), this.model.world.pxWidth+"px", this.model.world.pxHeight+"px", 15);
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
