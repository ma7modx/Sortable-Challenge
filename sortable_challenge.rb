# http://sortable.com/challenge/
# gem install json
require 'json'
# require 'byebug'
load 'results_generator.rb'

def main()
 result_generator = ResultsGenerator.new("products.txt", "listings.txt")

 manufacturers_hash = ResultsGenerator.hash_column_to_list_of_objects( result_generator.products , "manufacturer" )
 manufacturer_model_hash = ResultsGenerator.hash_manufacturer_model_products( result_generator.products )

 result_generator.generate_results(manufacturers_hash, manufacturer_model_hash)
 result_generator.export_output("results.txt")
end

main()
