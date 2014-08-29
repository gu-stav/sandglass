encode = ( url ) ->
  encodeURIComponent( url )

decode = ( url ) ->
  decodeURIComponent( url )

module.exports =
  encode: encode
  decode: decode