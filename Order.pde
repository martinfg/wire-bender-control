import java.util.Map;

public enum Order {
    HELLO(0),
    ALREADY_CONNECTED(1),
    RECEIVED(2),
    ERR(3),
    ISALIVE(4),
    STOP(5),
    FEEDER(10),
    BENDER(11),
    ZAXIS(12),
    PIN(13),
    TEST(14),
    SETHOMED(20),
    ISHOMED(21),
    DELHOMED(22),
    ERR_NOTHOMED(23),
    BEND(25);
    
    private int value;
    private static Map map = new HashMap<Integer, String>();
    
    private Order(int value) {
        this.value = value;
    }

    static {
        for (Order order : Order.values()) {
            map.put(order.value, order);
        }
    }

    public static Order valueOf(int order) {
        return (Order) map.get(order);
    }

    public int getValue() {
        return value;
    }
}
