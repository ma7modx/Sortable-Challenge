module StringMatching

  def edit_distance(str1, str2, insert_cost = 1, delete_cost = 1, sub_cost = 1.5)
    dp = Array.new(str1.length+1) { Array.new(str2.length+1) }

    for i in 0...dp.size
      dp[i][0] = i
    end
    for j in 0...dp[0].size
      dp[0][j] = j
    end

    for i in 1...dp.size
      for j in 1...dp[i].size
        if str1[i-1] == str2[j-1]
          dp[i][j] = dp[i-1][j-1]
        else
          dp[i][j] = [
                      dp[i][j-1] + insert_cost,
                      dp[i-1][j] + delete_cost,
                      dp[i-1][j-1] + sub_cost,
                     ].min
        end
      end
    end

    return dp[dp.size-1][dp[0].size-1]
  end

  def calculate_words_similarity(word1, word2, substr_factor_w1_of_w2 = 0.2, substr_factor_w2_of_w1 = 1)
  if word1 == word2 # equal
    return 0
  elsif word2.index(word1) # substring
    return (word2.length - word1.length).abs * substr_factor_w1_of_w2
  elsif word1.index(word2)
    return (word2.length - word1.length).abs * substr_factor_w2_of_w1
  else # calculate edit distance
    return edit_distance(word1, word2)
  end
  end

  def find_best_match(word, list, breaking_threshold = 0.5)
    min_distance = 100000.0
    min_element = ""
    list.each { |element|

      element = element.downcase
      distance = calculate_words_similarity(element, word)

      if distance < min_distance
        min_distance = distance
        min_element = element
      end
      if min_distance <= breaking_threshold
        break
      end
    } # manufacturer
    return { "distance" => min_distance, "word" => min_element }
  end

  def acceptance_criteria(matching, val = 0.4)
    if matching["word"] == nil
      return false
    end

    if Float(matching["distance"]) / Float(matching["word"].length) <= val
      return true
    else
      return false
    end
  end
end
