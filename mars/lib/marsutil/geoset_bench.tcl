package require marsutil
package require util
namespace import ::marsutil::* 
namespace import ::util::*

geoset gs

gs create line R001 {
    20  0     22   5     19 10     20 14     24 18
    19 24     20  26     35 28     40 27     47 30
    50 39     46  45     48 55     45 61     38 60
    35 58     30  60     28 66     30 69     37 70
    41 67     44  70     43 78     41 80     40 85
    45 90     47 100
} river

gs create line R002 {
     0 40      5 40     20 50     29 50     33 48
    35 43     35 37     38 32     35 28
} river

gs create polygon N001 {
    5 55     15 60     16 72     19 79     15 90     4 85     0 70
} nbhood 

gs create polygon N002 {
    22 77     27 77     34 89     29 95     28 100     15 90     19 79
} nbhood 

gs create polygon N003 {
    40 85     45 90     47 100     28 100     29 95     34 89
} nbhood

gs create polygon N004 {
    45 90     55 90     60 100     47 100
} nbhood

gs create polygon N005 {
    55 75     70 72     60 100     55 90     50 82
} nbhood

gs create polygon N006 {
    15 60     24 61     22 65     18 68     16 72
} nbhood

gs create polygon N007 {
    18 68     20 73     25 68     22 77     19 79     16 72
} nbhood

gs create polygon N008 {
    25 68     29 73     27 77     22 77
} nbhood

gs create polygon N009 {
    29 73     41 80     40 85     34 89     27 77
} nbhood

gs create polygon N010 {
    43 78     50 82     55 90     45 90     40 85     41 80
} nbhood

gs create polygon N011 {
    22 65     25 69     20 73     18 68
} nbhood

gs create polygon N012 {
    24 61     28 66     30 69     29 73     25 69     22 65
} nbhood

gs create polygon N013 {
    30 69     37 70     41 80     29 73
} nbhood

gs create polygon N014 {
    37 70     44 70     43 78     41 80
} nbhood

gs create polygon N015 {
    50 68     55 75     50 82     43 78     44 70
} nbhood

gs create polygon N016 {
    5 40     20 50     15 55     15 60     5 55
} nbhood

gs create polygon N017 {
    15 55     25 57     24 61     15 60
} nbhood

gs create polygon N018 {
    25 57     30 60     28 66     24 61
} nbhood

gs create polygon N019 {
    35 58     38 60     35 64     28 66     30 60
} nbhood

gs create polygon N020 {
    35 64     41 67     37 70     30 69     28 66
} nbhood

gs create polygon N021 {
    41 67     44 70     37 70
} nbhood

gs create polygon N022 {
    38 60     45 61     50 63     50 68     44 70     41 67     35 64
} nbhood

gs create polygon N023 {
    49 60     55 60     55 75     50 68     50 63
} nbhood

gs create polygon N024 {
    58 46     67 49     68 60     70 72     55 75     55 60     58 52
} nbhood

gs create polygon N025 {
    20 50     29 50     30 55     25 57     15 55
} nbhood

gs create polygon N026 {
    30 55     33 56     35 58     30 60     25 57
} nbhood

gs create polygon N027 {
    34 53     39 56     38 60     35 58     33 56
} nbhood

gs create polygon N028 {
    44 53     48 55     45 61     38 60     39 56     44 57
} nbhood

gs create polygon N029 {
    51 54     49 60     50 63     45 61     48 55
} nbhood

gs create polygon N030 {
    52 45     58 46     58 52     55 60     49 60     51 54
} nbhood

gs create polygon N031 {
    21 35     22 45     20 50     5 40     9 37
} nbhood

gs create polygon N032 {
    30 42     35 43     33 48     29 50     20 50     22 45     28 46
} nbhood

gs create polygon N033 {
    33 48     34 53     33 56     30 55     29 50
} nbhood

gs create polygon N034 {
    33 48     40 50     44 53     44 57     39 56     34 53
} nbhood

gs create polygon N035 {
    41 44     46 45     48 55     44 53     40 50
} nbhood

gs create polygon N036 {
    46 45     52 45     51 54     48 55
} nbhood

gs create polygon N037 {
    19 24     20 26     21 35     9 37     5 25
} nbhood

gs create polygon N038 {
    20 26     34 33     30 35     28 39     30 42     28 46     22 45
    21 35
} nbhood

gs create polygon N039 {
    30 35     35 37     35 43     30 42     28 39
} nbhood

gs create polygon N040 {
    35 43     41 44     40 50     33 48
} nbhood

gs create polygon N041 {
    35 37     40 40     41 44     35 43
} nbhood

gs create polygon N042 {
    45 37     50 39     46 45     41 44     40 40
} nbhood

gs create polygon N043 {
    50 39     60 40     58 46     52 45     46 45
} nbhood

gs create polygon N044 {
    69 30     67 49     58 46     60 40     59 35     61 33
} nbhood

gs create polygon N045 {
    10  0     20 0     22 5     19 10     20 14     24 18     19 24     
     5 25     7 10
} nbhood

gs create polygon N046 {
    24 18     35 20     40 27     35 28     20 26     19 24
} nbhood

gs create polygon N047 {
    20 26     35 28     38 32     34 33
} nbhood

gs create polygon N048 {
    38 32     35 37     30 35     34 33
} nbhood

gs create polygon N049 {
    38 32     42 32     45 37     40 40     35 37
} nbhood

gs create polygon N050 {
    40 27     47 30     50 39     45 37     42 32     38 32     35 28
} nbhood

gs create polygon N051 {
    51 29     51 33     55 35     59 35     60 40     50 39     47 30
} nbhood

gs create polygon N052 {
    20 0     35 3     35 20     24 18     20 14     19 10     22 5
} nbhood

gs create polygon N053 {
    35 3     62 7     55 29     43 20     35 20
} nbhood

gs create polygon N054 {
    35 20     43 20     42 25     40 27
} nbhood

gs create polygon N055 {
    42 25     51 29     47 30     40 27
} nbhood

gs create polygon N056 {
    43 20     55 24     51 29     42 25
} nbhood

gs create polygon N057 {
    55 24     61 33     59 35     55 35     51 33     51 29
} nbhood

gs create polygon N058 {
    62 7     70 13     69 30     61 33     55 24
} nbhood

puts "bbox: [gs bbox]"

puts "id at 35,50: <[gs find {35 50} nbhood]>"

puts "bench: [time {gs find {35 50} nbhood} 10000]"
