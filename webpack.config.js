var webpack = require("webpack"),
	path = require("path"),
	CleanWebpackPlugin = require("clean-webpack-plugin"),
	CopyWebpackPlugin = require("copy-webpack-plugin"),
	HtmlWebpackPlugin = require("html-webpack-plugin"),
	WriteFilePlugin = require("write-file-webpack-plugin");

// load the secrets
var alias = {};

var fileExtensions = [
	"jpg",
	"jpeg",
	"png",
	"gif",
	"eot",
	"otf",
	"svg",
	"ttf",
	"woff",
	"woff2"
];
alias.utils = path.join(__dirname, "src/utils.coffee");
// alias['needsharebutton.m ``in.js'] = path.join(__dirname, 'needsharebutton.min.js');
// alias['needsharebutton.css'] = path.join(__dirname, 'needsharebutton.css');
// alias['font-awesome.css'] = path.join(__dirname, 'css/font-awesome.css');
// alias['needsharebutton.css'] = path.join(__dirname, 'needsharebutton.css');

var options = {
	mode: process.env.NODE_ENV || "development",
	entry: {
		option: path.join(__dirname, "src", "option", "option.coffee"),
		player: path.join(__dirname, "src", "content", "player.coffee"),
		authorized: path.join(__dirname, "src", "content", "authorized.coffee"),
		background: path.join(__dirname, "src", "background", "main.js")
	},
	output: {
		path: path.join(__dirname, "build"),
		filename: "[name].bundle.js"
	},
	module: {
		rules: [
			{
				test: /\.css$/,
				loader: "style-loader!css-loader"
				// exclude: /node_modules/
			},
			{
				test: /\.less$/,
				use: [
					{
						loader: "style-loader" // creates style nodes from JS strings
					},
					{
						loader: "css-loader" // translates CSS into CommonJS
					},
					{
						loader: "less-loader" // compiles Less to CSS
					}
				]
			},
			{
				test: new RegExp(".(" + fileExtensions.join("|") + ")$"),
				loader: "file-loader?name=[name].[ext]"
				// exclude: /node_modules/
			},
			{
				test: /\.html$/,
				loader: "html-loader",
				exclude: /node_modules/
			},
			{
				test: /\.coffee$/,
				loader: "coffee-loader"
			}
		]
	},
	resolve: {
		alias: alias
	},
	plugins: [
		// clean the build folder
		new CleanWebpackPlugin(["build"]),
		// expose and write the allowed env vars on the compiled bundle
		new webpack.EnvironmentPlugin(["NODE_ENV"]),
		new CopyWebpackPlugin([
			{
				from: "src/manifest.json",
				transform: function(content) {
					// generates the manifest file using the package.json informations
					const json = {
						description: process.env.npm_package_description,
						version: process.env.npm_package_version,
						...JSON.parse(content.toString())
					};

					if (options.devtool === "cheap-module-eval-source-map") {
						json["content_security_policy"] =
							"script-src 'self' 'unsafe-eval'; object-src 'self'";
					}

					return Buffer.from(JSON.stringify(json));
				}
			},
			{
				from: "src/images",
				to: "images"
			}
		]),
		new HtmlWebpackPlugin({
		    template: path.join(__dirname, "src", "player.html"),
		    filename: "player.html",
		    chunks: ["player"]
		}),
		new HtmlWebpackPlugin({
		    template: path.join(__dirname, "src", "authorized.html"),
		    filename: "authorized.html",
		    chunks: ["authorized"]
		}),
		new HtmlWebpackPlugin({
			template: path.join(__dirname, "src", "option.html"),
			filename: "option.html",
			chunks: ["option"]
		}),
		new HtmlWebpackPlugin({
			template: path.join(__dirname, "src", "background.html"),
			filename: "background.html",
			chunks: ["background"]
        }),
        
        new webpack.ProvidePlugin({
			jQuery: "jquery"
        }),
        
		new WriteFilePlugin()
	]
};

module.exports = options;
