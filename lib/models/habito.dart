class Habito{
  final String id; //el id lo pongo final ya que nunca cambia los demas si
  String nombre;
  int color;
  List<String> fechasCompletadas;

  Habito({
    required this.id, //el campo requiered te obliga a pasar los datos que se pide
    required this.nombre,
    required this.color,
    List<String>? fechasCompletadas,
  }) : fechasCompletadas = fechasCompletadas ?? [];

  static String claveFecha(DateTime d) =>
      '${d.year.toString().padLeft(4,'0')}-' //el termino padleft() rellena con ceros a la izquieda para que el mes en vez de 3 sea 03
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  //completadoHoy convierte la fehca de hoy en texto y mira si esta en la lista
  bool get completadoHoy => fechasCompletadas.contains(claveFecha(DateTime.now()));
  //totalCompletados es simplemente coatas fejcas hay
  int get totalCompletados => fechasCompletadas.length;
  int get rachaActual{
    //toSet() conviete la lista en un conj8tos donde bucar es mas rapido
    /*si hoy aun no esta hecho empezaremos a contar desde ayer asi
     la racho no se pierde mientras el dia no ha acabado*/
    final set = fechasCompletadas.toSet();
    var dia = DateTime.now();
    if(!set.contains(claveFecha(dia))){
      dia = DateTime(dia.year, dia.month, dia.day - 1);
    }
    var racha = 0;
    /*este bucle va a ir dia a dia hacia atras sumando 1 mientras
    la fehcas este completada y parara el el primer dia que falte*/
    while(set.contains(claveFecha(dia))){
      racha++;
      dia = DateTime(dia.year, dia.month, dia.day -1);
    }
    return racha;
  }

  void alternaHoy(){
    final hoy = claveFecha(DateTime.now());
    if(fechasCompletadas.contains(hoy)){
      fechasCompletadas.remove(hoy);
    }else{
      fechasCompletadas.add(hoy);
    }
  }

  //tojson() pasa el objeto de un map (clave -> valor) y luego el servicio lo convertra en tecto
  Map<String, dynamic> toJson() =>{
    'id': id,
    'nombre': nombre,
    'color': color,
    'fechas': fechasCompletadas,
  };

  //fromJson() hace lo contrario recibe el map que sale de jsondecode y contruye u habito
  //factory es un contructor que puede devolver un objeto a parti de otrso datos
  //el termino as String le deice a dart el tipo real de cada valor
  factory Habito.fromJson(Map<String, dynamic> json) => Habito(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    color: json['color'] as int,
    fechasCompletadas:
    //(json['fechas'] as List?) ?? const [] protege contra el caso null : si no hubiera fehcas guardads usa una lista vaicao en ves de romper
    List<String>.from((json['fechas'] as List?) ?? const []),
  );
}

