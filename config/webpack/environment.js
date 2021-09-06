// config/webpack/environment.js
const { environment } = require('@rails/webpacker')
const erb = require('./loaders/erb')
const webpack = require('webpack')

environment.plugins.prepend(
    'Provide',
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      jquery: 'jquery',
      'window.jQuery': 'jquery',
      Popper: ['popper.js', 'default'],
      DataTable: 'datatables.net-dt/js/dataTables.dataTables'
    })
)

environment.loaders.prepend('erb', erb)
module.exports = environment
