import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'alumno.dart';

part 'grupo.g.dart';

@JsonSerializable()
class Grupo extends Equatable {
  final String group;
  final String classroom;
  final String subject;
  final int period;
  final List<Alumno> students;

  const Grupo({
    required this.group,
    required this.classroom,
    required this.subject,
    required this.period,
    required this.students,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) => _$GrupoFromJson(json);

  Map<String, dynamic> toJson() => _$GrupoToJson(this);

  @override
  List<Object?> get props => [group, classroom, subject, period, students];

  String get nombre => 'Grupo $group';
  String get materia => subject;
  int get totalAlumnos => students.length;
  String get infoCompleta => '$subject - Grupo $group (Periodo $period)';
  String get aula => classroom;
}
