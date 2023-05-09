// Copyright (c) 2023 David N Main

import SwiftUI
//import SequenceDiagram

struct ContentView: View {
    @State private var darkScheme = false

    let s = Actor("Strawberry")
    let a = Part("*Apples*")
    let p = Part("Prunes")
    let b = Part("**Oranges**\nBananas")

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Toggle(isOn: $darkScheme) { Text("Dark") }
            }
            Divider()

            SequenceDiagramCanvas {
                s ; a ; p ; b

                "Journey's start".note(over: s)

                a.activate
                b.activate

                "Say *Hello*\n**World**".from(a, to: b).activate
                "reminder\nto self".toSelf(b).deactivate
                "This is a really long message that increases the gap".from(b, to: a).activate
                "self message".toSelf(a).dashed.deactivate.activate
                "Return supplies".from(a, to: p).openArrow.deactivate.activate
                a.deactivate
                10
                "Phase Tran ksition"
                10
                "The *Apples* spoke to me".from(p, to: s).deactivate
                40
                "The ***Apples*** feel sad and unwanted".note(from: a, to: p)

                b.deactivate
            }
        }
        .padding()
//        .preferredColorScheme(darkScheme ? .dark : .light)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 1000, height: 1000)
    }
}
