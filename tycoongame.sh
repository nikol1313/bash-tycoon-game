#!/bin/bash
trade_tycoon() {
    local money=1000
    local week=1
    local unlock_cost=100000
# can add or remove if u want
    local active_items=(
        "Wood" "Iron" "Wheat" "Cloth" "Leather"
        "Coal" "Copper" "Stone" "Salt" "Glass"
        "Ale" "Rations" "Torches" "Herbs" "Arrows"
    )
# same as here
    local locked_items=(
        "Silver" "Gold" "Gems" "Potions" "Scrolls"
        "Holy Water" "Mithril" "Adamantine" "Elven Silk"
        "Dragon Scales" "Magic Wands" "Spellbooks"
        "Troll Blood" "Phoenix Feathers" "Unicorn Horns"
        "Vorpal Blades" "Philosopher's Stone"
    )

    local -A inventory
    local -A market_prices
    local -A average_cost
    local -a current_market

    local item price qty cost revenue action new_item item_idx max_qty
    local -a shuffled

    for item in "${active_items[@]}"; do
        inventory["$item"]=0
        average_cost["$item"]=0
    done

    __tycoon_generate_market() {
        current_market=()
        market_prices=()
        shuffled=($(shuf -e "${active_items[@]}"))
        local i
        for i in {0..5}; do
            item="${shuffled[$i]}"
            current_market+=("$item")
            price=$(( (RANDOM % 40) + 10 ))
            market_prices["$item"]=$price
        done
    }

    __tycoon_generate_market

    while true; do
        clear
        echo "========================================="
        echo "   MED MERCHANT - Week $week        "
        echo "========================================="
        echo " Gold Pieces: $money GP"
        echo "-----------------------------------------"
        echo " YOUR WAGON (Inventory):"
        local has_items=0
        for item in "${!inventory[@]}"; do
            if [ "${inventory[$item]}" -gt 0 ]; then
                echo "  - $item: ${inventory[$item]} (Avg Paid: ${average_cost[$item]} GP)"
                has_items=1
            fi
        done
        if [ $has_items -eq 0 ]; then
            echo "  (Empty)"
        fi
        echo "-----------------------------------------"
        echo " THIS WEEK'S LOCAL MARKET:"
        local i=1
        for item in "${current_market[@]}"; do
            echo "  [$i] $item: ${market_prices[$item]} GP"
            ((i++))
        done
        echo "========================================="

        echo "Actions: [B]uy | [S]ell | [N]ext Week | [U]nlock Item ($unlock_cost GP) | [Q]uit"
        read -p "What would you like to do? " action

        case ${action,,} in
            b)
                read -p "Enter market item number to buy (1-${#current_market[@]}): " item_idx
                if [[ "$item_idx" =~ ^[0-9]+$ ]] && [ "$item_idx" -ge 1 ] && [ "$item_idx" -le "${#current_market[@]}" ]; then
                    item="${current_market[$((item_idx-1))]}"
                    price=${market_prices[$item]}
                    max_qty=$(( money / price ))
                    if [ "$max_qty" -gt 0 ]; then
                        read -p "How many? (Max: $max_qty): " qty
                        if [[ "$qty" =~ ^[0-9]+$ ]] && [ "$qty" -gt 0 ]; then
                            if [ "$qty" -le "$max_qty" ]; then
                                cost=$(( price * qty ))
                                local current_qty=${inventory["$item"]}
                                local current_avg=${average_cost["$item"]}
                                local current_total_value=$(( current_qty * current_avg ))
                                local new_total_value=$(( current_total_value + cost ))
                                local new_qty=$(( current_qty + qty ))
                                average_cost["$item"]=$(( new_total_value / new_qty ))
                                money=$(( money - cost ))
                                inventory["$item"]=$new_qty
                                echo "Bought $qty $item for $cost GP!"
                                sleep 1
                            else
                                echo "You don't have enough Gold Pieces for that many!"
                                sleep 1
                            fi
                        else
                            echo "Invalid quantity."
                            sleep 2
                        fi
                    else
                        echo "You can't even afford one $item!"
                        sleep 2
                    fi
                else
                    echo "Invalid item number!"
                    sleep 2
                fi
                ;;
            s)
                read -p "Enter market item number to sell (1-${#current_market[@]}): " item_idx
                if [[ "$item_idx" =~ ^[0-9]+$ ]] && [ "$item_idx" -ge 1 ] && [ "$item_idx" -le "${#current_market[@]}" ]; then
                    item="${current_market[$((item_idx-1))]}"
                    price=${market_prices[$item]}
                    max_qty=${inventory["$item"]}
                    if [ "$max_qty" -gt 0 ]; then
                        read -p "How many? (Max: $max_qty): " qty
                        if [[ "$qty" =~ ^[0-9]+$ ]] && [ "$qty" -gt 0 ]; then
                            if [ "$qty" -le "$max_qty" ]; then
                                revenue=$(( price * qty ))
                                money=$(( money + revenue ))
                                inventory["$item"]=$(( inventory["$item"] - qty ))
                                if [ "${inventory["$item"]}" -eq 0 ]; then
                                    average_cost["$item"]=0
                                fi
                                echo "Sold $qty $item for $revenue GP!"
                                sleep 1
                            else
                                echo "You only have $max_qty $item in your wagon!"
                                sleep 1
                            fi
                        else
                            echo "Invalid quantity."
                            sleep 1
                        fi
                    else
                        echo "You don't have any $item to sell!"
                        sleep 1
                    fi
                else
                    echo "Invalid item number!"
                    sleep 1
                fi
                ;;
            n)
                week=$(( week + 1 ))
                __tycoon_generate_market
                ;;
            u)
                if [ "$money" -ge "$unlock_cost" ]; then
                    if [ ${#locked_items[@]} -gt 0 ]; then
                        money=$(( money - unlock_cost ))
                        new_item="${locked_items[0]}"
                        active_items+=("$new_item")
                        inventory["$new_item"]=0
                        average_cost["$new_item"]=0
                        locked_items=("${locked_items[@]:1}")
                        echo "GUILD PERMIT SECURED: $new_item added to market rotation!"
                        sleep 2
                    else
                        echo "You have already unlocked all the realm's items!"
                        sleep 1
                    fi
                else
                    echo "You need $unlock_cost GP to unlock a new item!"
                    sleep 1
                fi
                ;;
            q)
                echo "Safe travels, Merchant!"
                unset -f __tycoon_generate_market
                return 0
                ;;
            *)
                echo "Invalid option."
                sleep 1
                ;;
        esac
    done
}

trade_tycoon
