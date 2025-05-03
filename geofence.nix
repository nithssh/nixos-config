#{ pkgs }:
#
#pkgs.stdenv.mkDerivation {
#  name = "india-ipset";
#  src = pkgs.fetchurl {
#    url = "https://www.ipdeny.com/ipblocks/data/countries/in.zone";
#    sha256 = "0w0qrhcy26b99pdmy9p2qs5yf22bsgx2l9yqqdwiczkapbipkxqy";  # On 19 Mar 2025
#  };
#  unpackPhase = "true";  # No need to unpack a plain text file
#  installPhase = ''
#    mkdir -p $out
#    cp $src $out/india.zone
#  '';
#}

{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "india-ipset";
  src = pkgs.fetchurl {
    url = "https://www.ipdeny.com/ipblocks/data/countries/in.zone";
    sha256 = "0w0qrhcy26b99pdmy9p2qs5yf22bsgx2l9yqqdwiczkapbipkxqy";  # On 19 Mar 2025
  };
  unpackPhase = "true";  # No need to unpack a plain text file

  buildPhase = ''
    echo "Processing IP block list..."
    
    # Remove empty lines, and join with commas and quotes. Remove trailing comma
    #indiaIpsCsv=$(awk 'NF {print "\"" $0 "\""}' "$src" | tr '\n' ',' | sed 's/.$//')
    indiaIpsCsv=$(cat $src | tr '\n' ',' | sed 's/.$//')

    echo $indiaIpsCsv
 
    # Save to the output file.
    echo "$indiaIpsCsv" > processed.zone
  '';

  installPhase = ''
    mkdir -p $out
    cp processed.zone $out/india.zone
  '';
}

