import SwiftUI
import Combine
import shared

class ThingModel: ObservableObject {
    @Published
    var thing: Thing = Thing(count: -1)
    
    var cancellables = Set<AnyCancellable>()
    
    init(_ repository: ThingRepositoryIos) {
        createPublisher(flowWrapper: repository.getThingStreamWrapper(count: 100, succeed: true))
            .replaceError(with: Thing(count: -1))
            .receive(on: DispatchQueue.main)
            .sink { thing in self.thing = thing }
            .store(in: &cancellables)
    }
}

struct ThingView : View {
    @ObservedObject
    var thingModel: ThingModel
    
    init(_ repository: ThingRepositoryIos) {
        thingModel = ThingModel(repository)
    }
    
    var body: some View {
        Text("Count: \(thingModel.thing.count)")
    }
}
