extensions [
  csv
  matrix
]

breed [formigas]

globals[
   patch-fire
   number-of-fires

   list-of-fires
   list-of-ticks

   response-time
   average-response-time
   m-time-interval-visits

   frequency-of-visits

   sd-time-interval-visits
   sd-average-response-time
   sd-frequency-of-visits

   intrvl-visits

   curve-list
   index-list
   aux-index

   nb-ants-aux

   file

   turn-side
   turn-back

   cobertura
   percentage
   max-u-value
   checked

   sdf
   qmi

   number-of-coverages

   csv-curve-list
   ;tempQMI
   cluster
   set_clusters
   cluster-values

   watershed_patches
   ws-count

   mean-map
   map-matrix

   debug-cluster

   probabilistic_cluster

]

turtles-own[
  sucessor
  front-steps
  personal-curve-list
  own-matrix
  map-list
  timestamps

  guided
  destiny
  turn-guided
  ;already-sync

  guided-unlock
]

patches-own[
   u-value
   time-interval-visits
   visita-anterior
   color-set
]

to setup
  clear-all
  setup-patches
  setup-ants
  setup-lists
  set-file-name
  reset-ticks
end

to setup-patches

  ask patches [
    set pcolor white
    set u-value 0
    set time-interval-visits n-values 0[0]
    set visita-anterior 0

    set plabel u-value
    set plabel-color black

    set color-set 0
  ]

  set number-of-fires 0
  set average-response-time 0
  set frequency-of-visits 0
  set m-time-interval-visits 0

  set sd-time-interval-visits 0
  set sd-average-response-time 0
  set sd-frequency-of-visits 0

  set list-of-fires n-values 0[0]
  set list-of-ticks n-values 0[0]
  set response-time n-values 0[0]

  set turn-side 0
  set turn-back 0

  set cobertura 0
  set max-u-value 0
  set checked []
  set percentage [0]

  ;set tempQMI 0

  let i 0
  let j 0

  set mean-map 0


  repeat max-pxcor + 1 [
    set j 0

    repeat max-pycor + 1 [
      ifelse (remainder i 2 = 0)
        [ if(remainder j 2 != 0) [ ask patch i j [ set pcolor grey ] ] ]
        [ if(remainder j 2 = 0) [ ask patch i j [ set pcolor grey ] ] ]
      set j j + 1
    ]
    set i i + 1
  ]

  set cluster []
  set set_clusters[]
  set watershed_patches []
  set cluster-values[]

  set map-matrix []

  set debug-cluster []
  set probabilistic_cluster []

end

to setup-ants
  create-formigas 1[
    set shape "airplane"
    set size 1
    set heading 0

    set front-steps 0
    set personal-curve-list  n-values (max-pycor + 1) [0]

    let i 0
    let j 0
    set own-matrix []
    set map-list []
    let auxmap []
    set timestamps[]

    ;inicializando matriz de memoria de cada agente
    repeat max-pxcor + 1
    ;repeat 10
    [
      let temporary-list[]
      repeat max-pycor + 1
      ;repeat 10
      [
        set temporary-list lput 0 temporary-list

      ]

      set auxmap lput temporary-list auxmap
      set own-matrix lput temporary-list own-matrix
    ]

    repeat 4 ;change for number-of-turtles for other numbers
    [
      set map-list lput matrix:from-row-list auxmap map-list
      set timestamps lput 0 timestamps
    ]

    set own-matrix matrix:from-row-list own-matrix
    ;matrix:set own-matrix 0 0 matrix:get own-matrix 0 0 + 1;colocando ++ na primeira posição
    set guided false

    ask patch-here[
       ;set u-value u-value + 1
       set plabel u-value
       set time-interval-visits lput 0 time-interval-visits
       set visita-anterior 0
    ]

    set number-of-fires 0

    set destiny 0
    set turn-guided false
    set guided false

    set guided-unlock 0
  ]


end

;; Libera novos drones a cada intervalo de tempo especifico
to create-ants
  if(ticks mod time-between-ants = 0 and ticks > 1 and nb-ants-aux < (number-of-ants - 1))[
    set nb-ants-aux nb-ants-aux + 1
    setup-ants

  ]
end

to go
     create-ants

     ask formigas [
       ;adiciona +1 na posição para qual a turtle foi

       ;print (word "turtle")
       ;print who

       matrix:set own-matrix ([pycor] of patch-here) ([pxcor] of patch-here) (matrix:get own-matrix ([pycor] of patch-here) ([pxcor] of patch-here)) + 1

       let old-patch patch-here

       ask patch-here[
         set u-value u-value + 1;atualiza o u-value
         set plabel u-value
       ]

       set map-list replace-item who map-list own-matrix
       set timestamps replace-item who timestamps ticks

       let neighborMin 0

       let flag_lock false

       let first-turtle who
       if(patch-ahead 1 != nobody)
       [
         ask (turtles-on patch-ahead 1)
         [
           if (patch-ahead 1 != nobody)
           [
             if(member? first-turtle [who] of turtles-on patch-ahead 1)
             [set guided-unlock ticks]
           ]
         ]
       ]

       if (guided-unlock != 0)
       [ifelse(ticks - guided-unlock <= 3)
         [set flag_lock true]
         [set guided-unlock 0]
       ]

       ifelse(not guided) or (flag_lock)
       [
         set neighborMin min-of-4-matrix map-list timestamps ;retorna o patch com menor valor da vizinhança

         if(neighborMin != patch-here)
         [

           ifelse ( neighborMin = patch-ahead 1) or (front-steps = 0)
           [;se o menor for o logo a frente ele só soma 1 na variavel de passos a frente pro histograma de curvas
             set front-steps front-steps + 1
           ]
           [;caso contrario se for um dos lados ele marca turn-side + 1
            ; se for o logo atras ele marca turn-back + 1

             ;add1-curve-list
             ifelse ( neighborMin = patch-left-and-ahead 90 1 or neighborMin = patch-left-and-ahead -90 1)
             [set turn-side turn-side + 1]

             [if(neighborMin = patch-ahead -1)
               [set turn-back turn-back + 1]

             ]
           ]

           ;anda pro menor
           ;;TODO descomentar as duas linhas pra ele se mover
           face neighborMin
           move-to neighborMin
         ]
       ]

       [
         set neighborMin patch-here

         ifelse(turn-guided = false)
         [
           face patch [pxcor] of patch-here [pycor] of destiny
           if(patch-ahead 1  != nobody and not any? turtles-on patch-ahead 1)
           [set neighborMin patch-ahead 1
             move-to neighborMin]
           if(patch-here = patch [pxcor] of patch-here [pycor] of destiny) [set turn-guided true set turn-side turn-side + 1]
         ]
         [
           face patch [pxcor] of destiny [pycor] of patch-here
           if(patch-ahead 1  != nobody and not any? turtles-on patch-ahead 1)
           [set neighborMin patch-ahead 1
             move-to neighborMin]
           if(patch-here = patch [pxcor] of destiny [pycor] of patch-here) [set turn-guided false set guided false]
         ]

         ;move-to neighborMin
       ]
         ;set neighborMin

        ;;GUIDED PART
;         ifelse (ticks = 1)
;
;         [move-to patch 15 15]
;         [
;           if(guided = true)
;           [
;             ifelse(turn-guided = false)
;             ;
;             [
;               print "aqui4"
;               face patch [pxcor] of patch-here [pycor] of destiny
;               move-to patch-ahead 1
;               if(patch-here = patch [pxcor] of patch-here [pycor] of destiny) [print "aqui" set turn-guided true]
;             ]
;
;             [
;               face patch [pxcor] of destiny [pycor] of patch-here
;               move-to patch-ahead 1
;               if(patch-here = patch [pxcor] of destiny [pycor] of patch-here) [print "aqu2i" set turn-guided false set guided false]
;             ]
;           ]
;         ]



       let neighborMaps map-list
       let neighborTimes timestamps
       let flagsync 0
       ;let newMatrix []
       ;let flag 0;flag para saber se foi sincronizado ou nao

       let aux-guided guided

       ask other turtles-on patches in-radius 3
       [
           ;print (word "sync")
           ;print who
           ;set newMatrix sync-matrix own-matrix firstMatrix;passa a matriz das duas turtles para sincronizar
           ;set firstMatrix newMatrix
           ;let otherMatrix matrix:times newMatrix 1
           ;set flag 1
           ;set own-matrix otherMatrix
           ;
           let test matrix:times own-matrix 1
           set neighborMaps replace-item who neighborMaps test
           ;set neighborTimes lput item who ticks neighborTimes
           set neighborTimes replace-item who neighborTimes ticks
           set flagsync 1





       ]

       if (flagsync = 1)
       [set map-list neighborMaps
       set timestamps neighborTimes]

       if( (guided = false) and ((ticks mod 100) = 0))
       [
         ;print "wathershed call"
         set map-matrix own-matrix
         wathershed-start
         if(length set_clusters > 0)
         [

           let rand_pos random length probabilistic_cluster
           let cluster_pos item rand_pos probabilistic_cluster
           set destiny first (item cluster_pos set_clusters)
           set destiny patch (item 0 destiny)(item 1 destiny)
           set guided true
           set turn-guided false

           ;print destiny

           ;print matrix:pretty-print-text map-matrix
           ;print mean-map
           ;print cluster-values

           set debug-cluster set_clusters
           set map-matrix []
           set set_clusters []
           set cluster-values []
           set probabilistic_cluster []
           stop
         ]
         ;print set_clusters
       ]
;       if (flag = 1)
;       [set own-matrix newMatrix];seta o valor da matrix no agente inicial, caso tenha algum agente na volta em que o valor tambem foi alterado

       ask neighborMin[

         ifelse(length time-interval-visits = 0) ;atualiza o vetor de ticks para contabilizar os intervalos de visitas pela turtle
         [ set time-interval-visits lput ticks time-interval-visits ]
         [ set time-interval-visits lput (ticks - visita-anterior) time-interval-visits ]
         set visita-anterior ticks
       ]

       ;a parte a baixo é referente as coberturas
       ifelse (empty? checked);se for a primeira vez ele só seta o max-u-value, que é a variavel que guarda o maior u-value de todos pra dizer quantas posições tem o vetor
       [
         set max-u-value [u-value] of max-one-of patches [u-value];
         set checked lput 0 checked ;coloca 0 pra que nao se tenha uma lista vazia
       ]
       [
         if ([u-value] of max-one-of patches [u-value] > max-u-value)
         ;agora se nao for a primeira vez que o algoritmo roda ele testa se tem um novo maior u-value
         ;caso tenha ele atualiza o max-u-value e copia o antigo vetor de numero de patches
         [
           set max-u-value [u-value] of max-one-of patches [u-value]
           let newChecked [];vetor auxiliar pra fazer a copia
           let i 0
           while [i < length checked]
           [
             set newChecked lput item i checked newChecked
             set i i + 1
           ]
           set newChecked lput 0 newChecked
           set checked newChecked ; checked é o vetor que guarda o numero de patches ja cobertos, na posição 0 ele guarda o numero de patches com pelo menos u-value 1 e assim por diante
         ]
       ]

       ask old-patch [
         set checked replace-item (u-value - 1) checked (item (u-value - 1) checked + 1)
         ;adiciona um no vetor de checked. Por exemplo, se a turtle anda pra um patch e atualiza a posição pra 5, na posição 4 ele soma + 1
       ]

       ;print-matrix own-matrix
     ]
     percentage-calculator ;atualiza o vetor de percentage, que é o vetor de porcentagem de coberturas com relação ao vetor checked
     if(ticks = 4999 or ticks = 9999 or ticks =  14999 or ticks = 19999)[
       sdf-calculator ;recalcula e atualiza o sdf
       qmi-calculator ;recalcula e atualiza o qmi

       ask min-one-of patches [u-value][
         set number-of-coverages u-value
       ]
     ]




     ;ask formigas [ set guided false ]

     tick

end

to qmi-calculator
  let tempQMI 0
  let N_intervals 0;

  ask patches [
    foreach time-interval-visits[
       set tempQMI tempQMI + ? ^ 2
       set N_intervals N_intervals + 1
    ]
  ]
  set tempQMI tempQMI / N_intervals
  set qmi precision (sqrt tempQMI) 2
end

to sdf-calculator
  set sdf precision (standard-deviation [u-value] of patches) 2
end


to change-file
  set file user-new-file
end

to set-file-name

  if file = 0
  [
    let i 0
    set file (word "MM" i ".csv")
    while[ file-exists? file ]
    [
      set i i + 1
      set file (word "MM" i ".csv")
    ]
  ]
end

to export-to-csv
  if file-exists? file
  [ file-delete file ]
  file-open file
  file-print (word "Indices:")
  file-print csv:to-row index-list
  file-print (word "Total de curvas")
  ;file-print "\n"
  file-print csv:to-row curve-list

  let i 0

  while [i < count turtles]
  [
    file-print (word "Turtle" i)
    ask turtle i
    [
      file-print csv:to-row personal-curve-list
    ]
    set i i + 1
  ]

  file-close

  ;set aux-index aux-index + 1
end

to setup-lists

  let i 0
  set curve-list []
  set index-list []
  while [i <= max-pycor]
  [
    set curve-list lput 0 curve-list
    set index-list lput i index-list

    set i i + 1

  ]

end

to add1-curve-list

   let item-list item front-steps curve-list ;copia o numero atual de vezes que andou reto aquela quantidade
   set item-list item-list + 1               ; e adiciona 1 a esse numero
   set curve-list replace-item front-steps curve-list item-list ;coloca no lugar no antigo
   ;abaixo faz o mesmo, porem com a lista de cada agente
   let personal-item-list item front-steps personal-curve-list
   set personal-item-list personal-item-list + 1
   set personal-curve-list replace-item front-steps personal-curve-list personal-item-list

   set front-steps 1 ;poe o numero de passos dados como 1 pois zera e depois ele vai se mover uma vez pra frente em seguida
   set csv-curve-list csv:to-row curve-list


end

to-report min-of-4-matrix [matrixes times]

    let possible-patches []
    let menor 99999
    let flag 0

    ;primeiro testa todos os patches dos 4 vizinhos sao possiveis e se nao tem nenhuma turtle neles e poe os possiveis numa lista (possible-patches)
    if patch-ahead 1 != nobody and not any? turtles-on patch-ahead 1
    [
      let i 0
      let result 0
      repeat count formigas
      [
        if(ticks > 0)
        [
          let auxmatrix item i matrixes
          let uvalue matrix:get auxmatrix ([pycor] of patch-ahead 1) ([pxcor] of patch-ahead 1)
          ;let partial uvalue * ((item i times) / ticks)
          set result result + uvalue
          set i i + 1
        ]
      ]
      set possible-patches lput patch-ahead 1 possible-patches
      set menor result
    ]



    if patch-left-and-ahead 90 1 != nobody and not any? turtles-on patch-left-and-ahead 90 1
    [
      let i 0
      let result 0
      repeat count formigas
      [
        if(ticks > 0)
        [
          let auxmatrix item i matrixes
          let uvalue matrix:get auxmatrix ([pycor] of patch-left-and-ahead 90 1) ([pxcor] of patch-left-and-ahead 90 1)
         ;let partial uvalue * ((item i times) / ticks)
          set result result + uvalue
          set i i + 1
        ]
      ]

      if(result < menor)
      [
        set flag 1
        set menor result
        set possible-patches []
        set possible-patches lput patch-left-and-ahead 90 1 possible-patches
      ]
     ]



    if patch-left-and-ahead -90 1 != nobody and not any? turtles-on patch-left-and-ahead -90 1
    [
      let i 0
      let result 0
      repeat count formigas
      [
        if(ticks > 0)
        [
          let auxmatrix item i matrixes
          let uvalue matrix:get auxmatrix ([pycor] of patch-left-and-ahead -90 1) ([pxcor] of patch-left-and-ahead -90 1)
          ;let partial uvalue * ((item i times) / ticks)
          set result result + uvalue
          set i i + 1
        ]
      ]

      if(result < menor)
      [
        set menor result
        set possible-patches []
        set possible-patches lput patch-left-and-ahead -90 1 possible-patches
      ]
      if(result = menor and flag = 1)
      [
        set possible-patches []
        set possible-patches lput patch-left-and-ahead 90 1 possible-patches
        set possible-patches lput patch-left-and-ahead -90 1 possible-patches
        let randpatch item 0 shuffle possible-patches
        set possible-patches []
        set possible-patches lput randpatch possible-patches
      ]
     ]


    if patch-ahead -1  != nobody and not any? turtles-on patch-ahead -1
    [
      let i 0
      let result 0
      repeat count formigas
      [

        if(ticks > 0)
        [
          let auxmatrix item i matrixes
          let uvalue matrix:get auxmatrix ([pycor] of patch-ahead -1) ([pxcor] of patch-ahead -1)
          ;let partial uvalue * ((item i times) / ticks)
          set result result + uvalue
          set i i + 1
        ]
      ]

      if(result < menor)
      [
        set menor result
        set possible-patches []
        set possible-patches lput patch-ahead -1 possible-patches
      ]

     ]

    ifelse empty? possible-patches
    [report patch-here]
    [report item 0 possible-patches]

    ;let menor item 0 possible-patches

    ;acha o menor da lista

    ;let i 0
    ;while [i < length possible-patches]
    ;[
      ;let current item i possible-patches

      ;if matrix:get own-matrix ([pycor] of current) ([pxcor] of current) < matrix:get own-matrix ([pycor] of menor) ([pxcor] of menor)
      ;[
      ;  set menor current
      ;]
     ; set i i + 1
    ;]
    ;no final do loop menor tem o valor do menor

    ;if member? patch-ahead 1 possible-patches
;    ;[; aqui se o menor for o logo a frente dai retorna ele, caso contrario continua a execução
;      if matrix:get own-matrix ([pycor] of patch-ahead 1) ([pxcor] of patch-ahead 1) = matrix:get own-matrix ([pycor] of menor) ([pxcor] of menor)
;      [report patch-ahead 1];retorna o menor se ele for o logo a frente
;    ]
;
;    let sidelist []
;    set sidelist lput patch-left-and-ahead -90 1 sidelist
;    set sidelist lput patch-left-and-ahead 90 1 sidelist
;    ;guardou os dois dos lados no sidelist pra passar um random neles caso os dois dos lados estejam disponiveis
;
;    if (member? patch-left-and-ahead -90 1 possible-patches) and (member? patch-left-and-ahead 90 1 possible-patches)
;    [; se os dois  forem possiveis
;      if matrix:get own-matrix ([pycor] of patch-left-and-ahead 90 1) ([pxcor] of patch-left-and-ahead 90 1) = matrix:get own-matrix ([pycor] of menor) ([pxcor] of menor)
;      [; e um deles for o menor e os dois forem iguais dai ele passa um random e retorna
;        if matrix:get own-matrix ([pycor] of patch-left-and-ahead -90 1) ([pxcor] of patch-left-and-ahead -90 1) = matrix:get own-matrix ([pycor] of patch-left-and-ahead 90 1) ([pxcor] of patch-left-and-ahead 90 1)
;        [report item 0 shuffle sidelist]
;      ]
;    ]
;    if (member? patch-left-and-ahead 90 1 possible-patches)
;    [; caso nao caia na condição anterior ele testa só o de um lado
;      if matrix:get own-matrix ([pycor] of patch-left-and-ahead 90 1) ([pxcor] of patch-left-and-ahead 90 1) = matrix:get own-matrix ([pycor] of menor) ([pxcor] of menor)
;      [report patch-left-and-ahead 90 1]
;    ]
;    if (member? patch-left-and-ahead -90 1 possible-patches)
;    [; e depois testa do outro
;      if matrix:get own-matrix ([pycor] of patch-left-and-ahead -90 1) ([pxcor] of patch-left-and-ahead -90 1) = matrix:get own-matrix ([pycor] of menor) ([pxcor] of menor)
;      [report patch-left-and-ahead -90 1]
;    ]
;
;    ;por final se nao caiu em nenhuma das condições anteriores só resta testar o atras
;    if member? patch-ahead -1 possible-patches
;    [report patch-ahead -1]

end

to-report sync-matrix [matrix1 matrix2] ;sincroniza as duas matrizes passadas
  let matrix3 (matrix:plus matrix1 matrix2) ;matrix3 é a soma das matrizes 1 e 2

  let i 0
  let j 0
  while [i < max-pycor + 1]
  [
    set j 0
    while [j < max-pxcor + 1]
    [
      let value max (list (matrix:get matrix1 i j) (matrix:get matrix2 i j))
      matrix:set matrix3 i j value  ;e atribui na matriz q sera retornada
      set j j + 1
    ]
    set i i + 1
  ]

  report matrix3
end

to percentage-calculator
  let i 0
  let porcentagem n-values (length checked)[0] ;inicia uma lista porcentagem que é uma auxiliar da percentage
  let maxpatches (max-pycor + 1) * (max-pxcor + 1)
  while [i < length checked] ;checked é a lista que contem o numero de patches com cada u-value
  [
    let numchecked item i checked
    set numchecked numchecked * 100
    set porcentagem replace-item i porcentagem precision (numchecked / maxpatches) 2 ;calcula a porcentagem de cada valor da checked
    set i i + 1
  ]

  set percentage porcentagem ;atribui o valor a percentage, que é a lista de atualiza os plots

end

to print-matrix [matrix]
  if(member? ticks [2000 4000 6000 8000 10000 12000 14000 16000 18000 20000])
  [  set-file-name
     file-open file
     file-print (sentence (word "Turlte:") who)
     file-print (sentence (word "Tick:") ticks)
     file-print matrix:pretty-print-text matrix
     file-close ]
end


;to wathershed [x y]
;  let i 0
;  let flag_valid false
;  if test-valid-patch x y
;  [
;    set cluster lput (patch x y ) cluster
;    spread x y
;    set flag_valid true
;  ]
;  set i i + 1
;
;
;
;  if(flag_valid)
;  [
;    while [i < length cluster]
;    [
;      let selected-patch item i cluster
;      spread [pxcor] of selected-patch [pycor] of selected-patch
;      set i i + 1
;    ]
;  ]
;  if(not empty? cluster)
;  [set set_clusters lput cluster set_clusters
;   set cluster []
;   color-map]
;
;
;end
;
;
;
;
;to-report test-valid-patch [x y]
;  ;print patch x y
;  if (patch x y) != nobody
;  [
;
;    if (not (member? (patch x y)  cluster) and not (member? (patch x y) set_clusters)) and ([u-value] of (patch x y) < mean-map)
;    [
;      let i 0
;      let flag_return true
;
;      while [i < length set_clusters]
;      [
;        let aux_cluster item i set_clusters
;
;        set i i + 1
;        if( (member? (patch x y) aux_cluster) )
;        [
;          set flag_return false
;        ]
;      ]
;
;      report flag_return
;    ]
;
;  ]
;  report false
;
;end
;
;
;to spread [x y]
;  ;while[length cluster > ws-count]
;  ;[
;   ; let selected-patch item ws-count cluster
;  if( test-valid-patch (x - 1)(y - 1) )[set cluster lput patch(x - 1)(y - 1) cluster]
;  if( test-valid-patch (x    )(y - 1) )[set cluster lput patch(x    )(y - 1) cluster]
;  if( test-valid-patch (x + 1)(y - 1) )[set cluster lput patch(x + 1)(y - 1) cluster]
;
;  if( test-valid-patch (x - 1)(y    ) )[set cluster lput patch(x - 1)(y    ) cluster]
;  if( test-valid-patch (x + 1)(y    ) )[set cluster lput patch(x + 1)(y    ) cluster]
;
;
;  if( test-valid-patch (x - 1)(y + 1) )[set cluster lput patch(x - 1)(y + 1) cluster]
;  if( test-valid-patch (x    )(y + 1) )[set cluster lput patch(x    )(y + 1) cluster]
;  if( test-valid-patch (x + 1)(y + 1) )[set cluster lput patch(x + 1)(y + 1) cluster]
;  ;]
;
;end
;
;
;
;
;
;to color-map
;  let i 0
;  let j 0
;  while[(j < length set_clusters)]
;  [
;    while [(i < length item j set_clusters)]
;    [
;      let list-to-color item j set_clusters
;      let patch-to-color item i list-to-color
;      ask patch-to-color[
;        set color-set color-set + 1
;        set pcolor color-set
;      ]
;      set i i + 1
;    ]
;    set j j + 1
;  ]
;  ;set ws-count 0
;  ;if not empty? cluster
;  ;[set set_clusters lput cluster set_clusters]
;  ;set cluster []
;end

;
;to floodfill [x y]
;
;  ifelse((member? (patch x y)  cluster) or (member? (patch x y) set_clusters))
;  []
;  [
;  ask patch x y
;  [
;    visitados x y
;    ask patch (x - 1)(y - 1)
;    [ visitados (x - 1)(y - 1)]
;
;    ask patch (x)(y - 1)
;    [ visitados (x)(y - 1)]
;
;    ask patch (x + 1)(y - 1)
;    [ visitados (x + 1)(y - 1)]
;
;    ask patch (x - 1)(y)
;    [ visitados (x - 1)(y)]
;
;    ask patch (x + 1)(y)
;    [ visitados (x + 1)(y)]
;
;    ask patch (x - 1)(y + 1)
;    [ visitados (x - 1)(y + 1)]
;
;    ask patch (x)(y + 1)
;    [ visitados (x)(y + 1)]
;
;    ask patch (x + 1)(y + 1)
;    [ visitados (x + 1)(y + 1)]
;  ]
;  ;set visited-patches []
;  set set_clusters lput cluster set_clusters
;  ]
;end
;
;to visitados [x y ]
;  ask patch x y
;  [
;    if(u-value < mean-map)
;    [
;      set watershed_patches lput patch x y watershed_patches
;      set cluster lput patch x y cluster
;      ;print (sentence x y)
;      set color-set color-set + 1
;      set pcolor color-set
;    ]
;  ]
;end

to test-color
  ask patches
  [set pcolor 1]
end


;;mean of the map
to mean-the-map
  ;let min-value min [u-value] of patches
  ;let max-value max [u-value] of patches
  ;let diff floor ((max-value - min-value) / 3)
  ;set mean-map diff
  ;print "mean"
  let list-of-means []
  let i 0
  let row-numbers item 0 matrix:dimensions map-matrix
  ;print row-numbers
  let map-matrix-list matrix:to-row-list map-matrix

  while [i < row-numbers]
  [set list-of-means lput (mean item i map-matrix-list) list-of-means
   ; print list-of-means
  set i i + 1]

  set mean-map floor mean list-of-means
  ;if(mean-map != 0)
  ;[print mean-map]
  ;[set mean-map floor mean matrix:to-row-list map-matrix]
end

to mean-the-map-30percent
  ;let min-value min [u-value] of patches
  ;let max-value max [u-value] of patches
  ;let diff floor ((max-value - min-value) / 3)
  ;set mean-map diff
  ;print "mean"
  let list-of-means []
  let max-u 0
  let min-u 9999
  let i 0
  let row-numbers item 0 matrix:dimensions map-matrix
  ;print row-numbers
  let map-matrix-list matrix:to-row-list map-matrix

  while [i < row-numbers]
  [
    if(max item i map-matrix-list > max-u) [set max-u max item i map-matrix-list]
    if(min item i map-matrix-list > min-u) [set min-u min item i map-matrix-list]

    set i i + 1
  ]

  set mean-map floor (min-u + ((max-u - min-u) / 0.7))
  ;if(mean-map != 0)
  ;[print mean-map]
  ;[set mean-map floor mean matrix:to-row-list map-matrix]
end



;;first func to be called
to wathershed-start
  ;print "wathershed"
  mean-the-map
   ask patches with [pxcor > -1]
   [
     if (matrix-test-valid-patch (pxcor)  (pycor));print "oi"
     [ matrix-wathershed pxcor pycor ]

   ]
   choose-cluster
end

;;list and cluster control
to matrix-wathershed [x y]
;  let coordinates []
;  set coordinates lput x coordinates
;  set coordinates lput y coordinates

  let i 0
  let flag_valid false
  if matrix-test-valid-patch x y
  [
   ;set cluster lput (list x y) cluster
   clusterize x y
   matrix-spread x y
   set flag_valid true
  ]
  set i i + 1


  if(flag_valid)
  [
    while [i < length cluster]
    [
      let selected-patch item i cluster
      matrix-spread item 0 selected-patch item 1 selected-patch
      set i i + 1
    ]
  ]
  if(not empty? cluster)
  [
    set set_clusters lput cluster set_clusters
    set cluster []
  ]
end



;;testing valid patches
to-report matrix-test-valid-patch [x y]
  if (patch x y) != nobody
  [
    ;print "test"
    if (matrix:get map-matrix x y < mean-map)
    [

      if (not (member? (list x y) cluster))
      [

        let i 0
        let flag_return true

        while [i < length set_clusters]
        [
          let aux_cluster item i set_clusters

          set i i + 1
          if( (member? (list x y) aux_cluster) )
          [
            set flag_return false
          ]
        ]

        report flag_return

      ]
    ]

  ]
  report false
end



;;recursion part
to matrix-spread [x y]
  if( matrix-test-valid-patch (x - 1)(y - 1) );[set cluster lput (list (x - 1)(y - 1)) cluster]
  [clusterize (x - 1)(y - 1)]
  if( matrix-test-valid-patch (x    )(y - 1) );[set cluster lput (list (x    )(y - 1)) cluster]
  [clusterize (x    )(y - 1)]
  if( matrix-test-valid-patch (x + 1)(y - 1) );[set cluster lput (list (x + 1)(y - 1)) cluster]
  [clusterize (x + 1)(y - 1)]

  if( matrix-test-valid-patch (x - 1)(y    ) );[set cluster lput (list (x - 1)(y    )) cluster]
  [clusterize (x - 1)(y    )]
  if( matrix-test-valid-patch (x + 1)(y    ) );[set cluster lput (list (x + 1)(y    )) cluster]
  [clusterize (x + 1)(y    )]

  if( matrix-test-valid-patch (x - 1)(y + 1) );[set cluster lput (list (x - 1)(y + 1)) cluster]
  [clusterize (x - 1)(y + 1)]
  if( matrix-test-valid-patch (x    )(y + 1) );[set cluster lput (list (x    )(y + 1)) cluster]
  [clusterize (x    )(y + 1)]
  if( matrix-test-valid-patch (x + 1)(y + 1) );[set cluster lput (list (x + 1)(y + 1)) cluster]
  [clusterize (x + 1)(y + 1)]
end

to clusterize [x y]
  set cluster lput (list x y) cluster

  ;print "clusterize"
  ifelse(length cluster-values = length set_clusters)
  [
   ; print set_clusters
    set cluster-values lput ((matrix:get map-matrix x y) + 1) cluster-values
  ]
  [
    ;print cluster-values
    ;print set_clusters
    let parcial_sum (last cluster-values) + (matrix:get map-matrix x y)
    set parcial_sum parcial_sum + 1
    set cluster-values replace-item (length (cluster-values) - 1) (cluster-values) (parcial_sum)

  ]
end

to choose-cluster

  let number_of_clusters length set_clusters
  let i 0
  while [ i < number_of_clusters]
  [
    let aux length item i set_clusters
    set aux (floor (aux / 10)) + 1
    let j 0
    while [j < aux]
    [set probabilistic_cluster lput i probabilistic_cluster set j j + 1]
    set i i + 1
  ]
  ;print probabilistic_cluster
end
@#$#@#$#@
GRAPHICS-WINDOW
200
10
960
791
-1
-1
15.0
1
10
1
1
1
0
0
0
1
0
49
0
49
0
0
1
ticks
30.0

BUTTON
1035
105
1098
138
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1110
105
1172
138
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1181
475
1318
508
number-of-ants
number-of-ants
1
5
4
1
1
NIL
HORIZONTAL

SLIDER
1181
515
1321
548
time-between-ants
time-between-ants
1
2000
1
1
1
NIL
HORIZONTAL

TEXTBOX
1041
240
1191
270
The default file name will be NCResults.csv
12
0.0
1

BUTTON
1046
275
1173
308
Change file name
change-file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1041
565
1176
610
Cobertura (%)
percentage
17
1
11

MONITOR
1041
615
1176
660
Curvas de 90°
turn-side
17
1
11

MONITOR
1181
615
1316
660
Curvas de 180°
turn-back
17
1
11

MONITOR
1116
515
1173
560
QMI
qmi
17
1
11

MONITOR
1046
515
1103
560
SDF
sdf
17
1
11

PLOT
1041
320
1316
470
Cobertura (%)
Numero
Porcentagem
0.0
25.0
0.0
100.0
true
false
"set-plot-x-range 0 1\nset-plot-y-range 0 100" "ifelse(empty? checked)\n[set-plot-x-range 0 1\nset-histogram-num-bars 1]\n\n[set-plot-x-range 0 length checked\nset-histogram-num-bars length checked]\n\nhistogram percentage"
PENS
"default" 1.0 1 -14730904 true "histogram percentage" "histogram percentage"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="LRTA* 5k" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 5000</exitCondition>
    <metric>qmi</metric>
    <metric>sdf</metric>
    <metric>number-of-coverages</metric>
    <metric>turn-side</metric>
    <metric>turn-back</metric>
    <enumeratedValueSet variable="number-of-ants">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-ants">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="globalProbabilistic10k" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 10000</exitCondition>
    <metric>qmi</metric>
    <metric>sdf</metric>
    <metric>number-of-coverages</metric>
    <metric>turn-side</metric>
    <metric>turn-back</metric>
    <enumeratedValueSet variable="number-of-ants">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-ants">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="global15k" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 15000</exitCondition>
    <metric>qmi</metric>
    <metric>sdf</metric>
    <metric>number-of-coverages</metric>
    <metric>turn-side</metric>
    <metric>turn-back</metric>
    <enumeratedValueSet variable="number-of-ants">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-ants">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="global20k" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 20000</exitCondition>
    <metric>qmi</metric>
    <metric>sdf</metric>
    <metric>number-of-coverages</metric>
    <metric>turn-side</metric>
    <metric>turn-back</metric>
    <enumeratedValueSet variable="number-of-ants">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-ants">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Matrices" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 20001</exitCondition>
    <metric>qmi</metric>
    <metric>sdf</metric>
    <metric>number-of-coverages</metric>
    <metric>turn-side</metric>
    <metric>turn-back</metric>
    <enumeratedValueSet variable="number-of-ants">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-ants">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="global10k-2ants" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 10000</exitCondition>
    <metric>qmi</metric>
    <metric>sdf</metric>
    <metric>number-of-coverages</metric>
    <metric>turn-side</metric>
    <metric>turn-back</metric>
    <enumeratedValueSet variable="number-of-ants">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-ants">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="global10k-70percent" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 10000</exitCondition>
    <metric>qmi</metric>
    <metric>sdf</metric>
    <metric>number-of-coverages</metric>
    <metric>turn-side</metric>
    <metric>turn-back</metric>
    <enumeratedValueSet variable="number-of-ants">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-ants">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
