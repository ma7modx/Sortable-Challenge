require 'json'
load 'string_matching.rb'
include StringMatching

class ResultsGenerator
  # Array of hashes
  attr_accessor :products, :listings, :results

  def initialize(products_file_path, listings_file_path)
    products_file_string = File.read("products.txt")
    listings_file_string = File.read("listings.txt")

    self.products = create_array_of_hash_from_string_file( products_file_string )
    self.listings = create_array_of_hash_from_string_file( listings_file_string )
  end

  def generate_results(manufacturers_hash, manufacturer_model_hash)
    self.results = link_listing_items_with_products(self.listings, self.products, manufacturers_hash, manufacturer_model_hash)
  end

  def export_output(results_file_path)
    str = ""
    self.results.each{ |k, v|
      str += { product_name: k, listings: v}.to_json.to_s
      str += "\n"
    }
    File.write(results_file_path, str)
  end

  def self.hash_column_to_list_of_objects(obj, column)
    hash = {}
    obj.each { |item|
      hash[ item[column].downcase ] = []
    }
    obj.each { |item|
      hash[ item[column].downcase ].push(item)
    }
    return hash
  end

  def self.hash_manufacturer_model_products(products) # nested hash
    hash = {}
    products.each { |item|
      hash[ item["manufacturer"].downcase ] = {}
    }
    products.each_with_index{ |item, index|
      hash[ item["manufacturer"].downcase ][ item["model"].downcase ] = { "product_name" => item["product_name"], "index" => index }
    }
    return hash
  end

###########
  private
###########
    def create_array_of_hash_from_string_file(str)
      result = []
      str.each_line { |line|
        result.push( JSON.parse(line) )
      }
      return result
    end

    def match_manufacturers(listing, product_manufacturers_hash, column = "manufacturer")
      matched_manufacturers = [] # list that maps the listing to its manufacturer
      matched_manufacturer_words = {} # hash the words of listing with its distance and matched word
      listing.each_with_index { |listing_item, listing_item_index|

        puts("processing #{listing_item_index} ...")
        possible_matchings = [] # list that collects the matched words of this listing
        listing_item[column].split(" ").each { |listing_manufacturer_word|

          listing_manufacturer_word = listing_manufacturer_word.downcase
          if matched_manufacturer_words.has_key?(listing_manufacturer_word) # check if min distance already exist
            min_distance = matched_manufacturer_words[listing_manufacturer_word]["distance"]
            min_manufacturer = matched_manufacturer_words[listing_manufacturer_word]["word"]
            possible_matchings.push( { "distance" => min_distance, "word" => min_manufacturer } )
            next
          end

          matched_manufacturer = find_best_match(listing_manufacturer_word, product_manufacturers_hash.keys)

          matched_manufacturer_words[ listing_manufacturer_word ] = matched_manufacturer
          possible_matchings.push( matched_manufacturer )
       } # listing_manufacturer_word

        best_matching_distance, best_matching_index = possible_matchings.map{ |element| element["distance"] }.each_with_index.min
        if best_matching_index
          matched_manufacturers.push( possible_matchings[best_matching_index] )
       else
          matched_manufacturers.push( {"distance" => 100000, "word" => nil} )
       end
      } # listing

      return matched_manufacturers
      # return matched_manufacturer_words
    end

    def match_models(listing, manufacturers_hash, matched_manufacturers)
      matched_models = []
      matched_model_words = {}
      manufacturers_hash.keys.each{ |manufacturer| matched_model_words[manufacturer] = {} }

      listing.each_with_index { |listing_item, listing_item_index|

        if matched_manufacturers[listing_item_index]['word']
          models_for_current_manufacturer = manufacturers_hash[ matched_manufacturers [listing_item_index]['word'] ].map{ |v| v['model'] }
          current_manufacturer = matched_manufacturers [listing_item_index]['word']
        else
          matched_models.push( {"distance" => 100000, "word" => nil} )
          next
        end

        puts("processing #{listing_item_index} ...")

        possible_matchings = []
        listing_item["title"].split(" ").each{ |listing_title_word|

          listing_title_word = listing_title_word.downcase
          if matched_model_words[current_manufacturer].has_key?(listing_title_word)
            min_distance = matched_model_words[current_manufacturer][listing_title_word]["distance"]
            min_model = matched_model_words[current_manufacturer][listing_title_word]["word"]
            possible_matchings.push( { "distance" => min_distance, "word" => min_model } )
            next
          end

          matched_product_model = find_best_match(listing_title_word, models_for_current_manufacturer)
          matched_model_words[current_manufacturer][listing_title_word] = matched_product_model
          possible_matchings.push( matched_product_model )
          if matched_product_model["distance"] == 0
            break
          end
        }

          best_matching_distance, best_matching_index = possible_matchings.map{ |element| element["distance"] }.each_with_index.min
          matched_models.push( possible_matchings[best_matching_index] )
      }

      return matched_models
    end

    def link_listing_items_with_products(listing, products, manufacturers_hash, manufacturer_model_hash)

      matched_manufacturers = match_manufacturers(listing, manufacturers_hash, "manufacturer") # from manufacturer column
      matched_manufacturers_from_title = match_manufacturers(listing, manufacturers_hash, "title")
      # merge and find the best
      matched_manufacturers.each_with_index{ |item, i|
        manufacturer_column = matched_manufacturers[i]
        title_column = matched_manufacturers_from_title[i]
        matched_manufacturers[i] = title_column if manufacturer_column["distance"] > title_column["distance"]  }

      matched_models = match_models(listing, manufacturers_hash, matched_manufacturers)

      result = {}
      listing.each_with_index{ |item, i|
        if acceptance_criteria(matched_models[i], 0.3) && acceptance_criteria(matched_manufacturers[i], 0.6)
          product_name = manufacturer_model_hash[ matched_manufacturers[i]["word"] ][ matched_models[i]["word"] ]["product_name"]
          if result.has_key?(product_name)
            result[product_name].push( item )
          else
            result[product_name] = [ item ]
          end
        end
      }

      count = 0
      result.each{ |k,v| count += v.count}
      puts(count)
      return result
    end
end
