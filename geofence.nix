{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "india-ipset";
  src = pkgs.fetchurl {
    url = "https://www.ipdeny.com/ipblocks/data/countries/in.zone";
    sha256 = "3cce94ff20a10e26a4eacfb95df36b4a36186dec4ebed232277e8d560dc6f2a1";
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

