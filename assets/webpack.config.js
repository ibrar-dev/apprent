const fs = require('fs');
const path = require('path');
const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

const appsPath = path.resolve(__dirname, "js/apps");
const apps = fs.readdirSync(appsPath);
const entryPoints = {
  'js/app': path.resolve(__dirname, "js/app.js"),
  'js/users': path.resolve(__dirname, "js/users.js"),
  'js/landing': path.resolve(__dirname, "js/landing.js")
};

apps.forEach(file => {
  const fullPath = path.resolve(appsPath, file);
  if (fs.lstatSync(fullPath).isDirectory()) {
    entryPoints['js/' + path.basename(file)] = fullPath + '/index.js';
  }
});

const stylesPath = path.resolve(__dirname, "css");
const stylesheets = fs.readdirSync(stylesPath);
// const entryPoints = { app: path.resolve(__dirname, "js/app.js")};

stylesheets.forEach(file => {
  if (file === 'common') return;
  const fullPath = path.resolve(stylesPath, file);
  if (fs.lstatSync(fullPath).isDirectory()) {
    entryPoints['css/' + path.basename(file)] = fullPath + '/styles.scss';
  }
});

let plugins = [
  new CopyWebpackPlugin([
    {from: './static/', to: '.'}
  ]),
  new MiniCssExtractPlugin({filename: "[name].css"}),
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Popper: 'popper.js'
  }),
  new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),
];

if (process.env.NODE_ENV === 'production') {
  plugins = plugins.concat([
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify('production')
    })
  ]);
}

module.exports = (env, options) => {
  return {
    optimization: {
      minimizer: [
        new TerserPlugin({cache: true, parallel: true, sourceMap: false, extractComments: true}),
        new OptimizeCSSAssetsPlugin({})
      ]
    },
    devtool: 'cheap-module-source-map',
    entry: entryPoints,
    output: {
      path: path.resolve(__dirname, "../priv/static"),
      filename: "[name].js",
      publicPath: "/"
    },
    plugins: plugins,
    module: {
      rules: [
        {
          test: /\.jsx?$/,
          exclude: /node_modules/,
          use: [
            {loader: "babel-loader", options: {cacheDirectory: true}}
          ]
        },
        {
          test: /\.s?css$/,
          use: [
            MiniCssExtractPlugin.loader,
            'css-loader',
            {
              loader: 'postcss-loader',
              options: {sourceMap: true, config: {path: path.resolve(__dirname, '.postcssrc.yml')}}
            },
            'resolve-url-loader',
            {loader: 'sass-loader', options: {sourceMap: true}}
          ]
        },
        {
          test: [/\.bmp$/, /\.gif$/, /\.jpe?g$/, /\.png$/, /\.svg/, /\.eot/, /\.ttf/, /\.woff2?$/],
          loader: require.resolve('url-loader'),
          options: {
            limit: 10000,
            name: 'media/[name].[hash:8].[ext]'
          }
        },
        {
          test: /plugin\.css$/,
          loaders: [
            'style-loader', 'css',
          ],
        },
      ],
    },
  }
};
