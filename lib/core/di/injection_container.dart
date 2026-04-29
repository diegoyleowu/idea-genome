import 'package:get_it/get_it.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/repositories/idea_repository_impl.dart';
import '../../domain/repositories/idea_repository.dart';
import '../../presentation/blocs/idea/idea_bloc.dart';
import '../../presentation/blocs/category/category_bloc.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  final localDataSource = HiveLocalDataSource();
  await localDataSource.initialize();
  getIt.registerSingleton<LocalDataSource>(localDataSource);

  getIt.registerLazySingleton<IdeaRepository>(
    () => IdeaRepositoryImpl(localDataSource: getIt()),
  );

  getIt.registerFactory<IdeaBloc>(
    () => IdeaBloc(repository: getIt()),
  );

  getIt.registerFactory<CategoryBloc>(
    () => CategoryBloc(),
  );
}
