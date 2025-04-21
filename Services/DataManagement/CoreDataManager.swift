import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NeuroMemo")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Error al cargar el Core Data: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error al guardar el contexto: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    // Búsqueda genérica con predicado
    func fetch<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [T] {
        let entityName = String(describing: entityType)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error al recuperar entidades \(entityName): \(error)")
            return []
        }
    }
    
    // Crear una nueva entidad
    func create<T: NSManagedObject>(_ entityType: T.Type) -> T {
        let entityName = String(describing: entityType)
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: viewContext)!
        return T(entity: entity, insertInto: viewContext)
    }
    
    // Eliminar una entidad
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        saveContext()
    }
    
    // Eliminar todos los datos de un tipo de entidad
    func deleteAll<T: NSManagedObject>(_ entityType: T.Type) {
        let entityName = String(describing: entityType)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: viewContext)
            saveContext()
        } catch {
            print("Error al eliminar todas las entidades \(entityName): \(error)")
        }
    }
}