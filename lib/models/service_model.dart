class StudioService {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final List<String> deliverables;
  final String image;

  const StudioService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    required this.deliverables,
    required this.image,
  });
}
